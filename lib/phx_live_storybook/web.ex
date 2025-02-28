defmodule PhxLiveStorybook.Web do
  @moduledoc false

  @doc false
  def controller do
    quote do
      @moduledoc false

      use Phoenix.Controller, namespace: PhxLiveStorybook
      import Plug.Conn
      unquote(view_helpers())
    end
  end

  @doc false
  def view do
    quote do
      @moduledoc false

      use Phoenix.View,
        namespace: PhxLiveStorybook,
        root: "lib/phx_live_storybook/templates"

      unquote(view_helpers())
    end
  end

  @doc false
  def live_view do
    quote do
      @moduledoc false
      use Phoenix.LiveView,
        layout: {PhxLiveStorybook.LayoutView, "live.html"}

      unquote(view_helpers())
    end
  end

  @doc false
  def live_component do
    quote do
      @moduledoc false
      use Phoenix.LiveComponent
      unquote(view_helpers())
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import convenience functions for LiveView rendering
      import Phoenix.LiveView.Helpers
      import PhxLiveStorybook.StorybookHelpers

      alias PhxLiveStorybook.Router.Helpers, as: Routes
    end
  end

  @doc """
  Convenience helper for using the functions above.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
