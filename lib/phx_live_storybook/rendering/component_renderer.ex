defmodule PhxLiveStorybook.Rendering.ComponentRenderer do
  @moduledoc """
  Responsible for rendering your function & live components, for a given
  `PhxLiveStorybook.Story` or `PhxLiveStorybook.StoryGroup`.
  """

  alias Phoenix.LiveView.Engine, as: LiveViewEngine
  alias Phoenix.LiveView.HTMLEngine
  alias PhxLiveStorybook.{Story, StoryGroup}
  alias PhxLiveStorybook.TemplateHelpers

  @doc """
  Renders a story or a group of story for a component.
  """
  def render_story(fun_or_mod, story = %Story{}, template, extra_assigns, opts) do
    if TemplateHelpers.story_group_template?(template) do
      raise "Cannot use <.lsb-story-group/> placeholder in a story template."
    end

    heex =
      template_heex(
        template,
        story.id,
        fun_or_mod,
        Map.merge(story.attributes, extra_assigns),
        story.let,
        story.block,
        story.slots,
        opts[:playground_topic]
      )

    render_component_heex(fun_or_mod, heex, opts)
  end

  def render_story(
        fun_or_mod,
        %StoryGroup{id: group_id, stories: stories},
        template,
        group_extra_assigns,
        opts
      ) do
    heex =
      cond do
        TemplateHelpers.story_template?(template) ->
          for story = %Story{id: story_id} <- stories, into: "" do
            extra_assigns = Map.get(group_extra_assigns, story_id, %{})
            extra_assigns = Map.put(extra_assigns, :id, "#{group_extra_assigns.id}-#{story_id}")

            template_heex(
              template,
              "#{group_id}:#{story_id}",
              fun_or_mod,
              Map.merge(story.attributes, extra_assigns),
              story.let,
              story.block,
              story.slots,
              opts[:playground_topic]
            )
          end

        TemplateHelpers.story_group_template?(template) ->
          heex =
            for story = %Story{id: story_id} <- stories, into: "" do
              extra_assigns = %{group_extra_assigns | id: "#{group_extra_assigns.id}-#{story_id}"}

              extra_attributes =
                extract_placeholder_attributes(
                  template,
                  story.id,
                  opts[:playground_topic]
                )

              component_heex(
                fun_or_mod,
                Map.merge(story.attributes, extra_assigns),
                story.let,
                story.block,
                story.slots,
                extra_attributes
              )
            end

          template
          |> TemplateHelpers.set_template_id(group_id)
          |> TemplateHelpers.replace_template_story_group(heex)

        true ->
          TemplateHelpers.set_template_id(template, group_id)
      end

    render_component_heex(fun_or_mod, heex, opts)
  end

  @doc false
  def render_multiple_stories(fun_or_mod, story_or_group, stories, template, opts) do
    heex =
      cond do
        TemplateHelpers.story_template?(template) ->
          for story <- stories, into: "" do
            template_heex(
              template,
              story.id,
              fun_or_mod,
              story.attributes,
              story.let,
              story.block,
              story.slots,
              opts[:playground_topic]
            )
          end

        TemplateHelpers.story_group_template?(template) ->
          heex =
            for story <- stories, into: "" do
              extra_attributes =
                extract_placeholder_attributes(
                  template,
                  story.id,
                  opts[:playground_topic]
                )

              component_heex(
                fun_or_mod,
                story.attributes,
                story.let,
                story.block,
                story.slots,
                extra_attributes
              )
            end

          template
          |> TemplateHelpers.set_template_id(story_or_group.id)
          |> TemplateHelpers.replace_template_story_group(heex)

        true ->
          TemplateHelpers.set_template_id(template, story_or_group.id)
      end

    render_component_heex(fun_or_mod, heex, opts)
  end

  defp component_heex(fun, assigns, _let, nil, [], extra_attrs) when is_function(fun) do
    """
    <.#{function_name(fun)} #{attributes_markup(assigns)} #{extra_attrs}/>
    """
  end

  defp component_heex(fun, assigns, let, block, slots, extra_attrs)
       when is_function(fun) do
    """
    <.#{function_name(fun)} #{let_markup(let)} #{attributes_markup(assigns)} #{extra_attrs}>
      #{block}
      #{slots}
    </.#{function_name(fun)}>
    """
  end

  defp component_heex(module, assigns, _let, nil, [], extra_attrs) when is_atom(module) do
    """
    <.live_component module={#{inspect(module)}} #{attributes_markup(assigns)} #{extra_attrs}/>
    """
  end

  defp component_heex(module, assigns, let, block, slots, extra_attrs)
       when is_atom(module) do
    """
    <.live_component module={#{inspect(module)}} #{let_markup(let)} #{attributes_markup(assigns)} #{extra_attrs}>
      #{block}
      #{slots}
    </.live_component>
    """
  end

  defp template_heex(
         template,
         story_id,
         fun_or_mod,
         assigns,
         let,
         block,
         slots,
         playground_topic
       ) do
    extra_attributes = extract_placeholder_attributes(template, story_id, playground_topic)

    template
    |> TemplateHelpers.set_template_id(story_id)
    |> TemplateHelpers.replace_template_story(
      component_heex(fun_or_mod, assigns, let, block, slots, extra_attributes)
    )
  end

  defp extract_placeholder_attributes(template, _story_id, _topic = nil) do
    TemplateHelpers.extract_placeholder_attributes(template)
  end

  defp extract_placeholder_attributes(template, story_id, topic) do
    TemplateHelpers.extract_placeholder_attributes(template, {topic, story_id})
  end

  defp let_markup(nil), do: ""
  defp let_markup(let), do: "let={#{to_string(let)}}"

  defp attributes_markup(attributes) do
    Enum.map_join(attributes, " ", fn
      {name, val} when is_binary(val) -> ~s|#{name}="#{val}"|
      {name, val} -> ~s|#{name}={#{inspect(val, structs: false)}}|
    end)
  end

  defp render_component_heex(fun_or_mod, heex, opts) do
    quoted_code = EEx.compile_string(heex, engine: HTMLEngine)

    {evaluated, _} =
      Code.eval_quoted(quoted_code, [assigns: []],
        requires: [Kernel],
        aliases: eval_quoted_aliases(opts, fun_or_mod),
        functions: eval_quoted_functions(opts, fun_or_mod)
      )

    LiveViewEngine.live_to_iodata(evaluated)
  end

  defp eval_quoted_aliases(opts, fun_or_mod) do
    aliases = Keyword.get(opts, :aliases, [])
    eval_quoted_aliases([module(fun_or_mod) | aliases])
  end

  defp eval_quoted_aliases(modules) do
    for mod <- modules, reduce: [] do
      aliases ->
        alias_name = :"Elixir.#{mod |> Module.split() |> Enum.at(-1) |> String.to_atom()}"

        if alias_name == mod do
          aliases
        else
          [{alias_name, mod} | aliases]
        end
    end
  end

  defp eval_quoted_functions(opts, fun) when is_function(fun) do
    [
      {Phoenix.LiveView.Helpers, [live_file_input: 2]},
      {function_module(fun), [{function_name(fun), 1}]}
    ] ++ extra_imports(opts)
  end

  defp eval_quoted_functions(opts, mod) when is_atom(mod) do
    [
      {Phoenix.LiveView.Helpers, [live_component: 1, live_file_input: 2]}
    ] ++ extra_imports(opts)
  end

  defp extra_imports(opts), do: Keyword.get(opts, :imports, [])

  defp module(fun) when is_function(fun), do: function_module(fun)
  defp module(mod) when is_atom(mod), do: mod

  defp function_module(fun), do: Function.info(fun)[:module]
  defp function_name(fun), do: Function.info(fun)[:name]
end
