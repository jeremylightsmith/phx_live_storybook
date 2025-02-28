# CHANGELOG

## v0.4.0 (not yet released)

- change (breaking!): `live_storybook/2` is no longer serving assets. You must add
  `storybook_assets/1` to your router in a non CSRF-protected scope.
- feature: new search modal. Trigger it with `cmd-k` or `/` shortcuts.
- feature: theming. You can declare different themes in the application settings. The selected
  theme will be merged in all components assigns.
- feature: you can initialize the component playground with any story.
- feature: templates. You can provide HTML templates to render stories, which can help with modals,
  slide-overs... (see this [guide](guides/components.md) for more details).
- feature: provide custom aliases & imports to your stories/templates
  (see this [guide](guides/components.md) for more details).
- feature: you can provide a `let` attribute to your inner blocks.
- improvement: storybook playground is now responsive.
- bugfix: fixed pre-opened folders always reopening themselves after each patch.
- bugfix: empty inner_block are no longer passed to all components.
- bugfix: fixed closing tag typo in code preview.
- documentation: new [`theming.md`](guides/theming.md) guide.
- documentation: new [`components.md`](guides/components.md) guide.

## v0.3.0 (2022-08-18)

- change (breaking!): entries must now be written as `.exs` files. Otherwise, they will be ignored.
- change (breaking!): `variations` have been rebranded as `stories`.
- change (breaking!): `live_storybook/2` must be set in your `router.ex` outside your main scope
  and outside your `:browser` pipeline.
- feature: new Playground tab to play with your components! To use it, you must declare attributes
  in your component entries.
- feature: you can opt-in iframe rendering for any of your components with `def container, do: :iframe`
- improvement: storybook is now fully responsive.
- improvement: meaningful errors are raised during compilation if your entries are invalid.
- improvement: improved storybook CSS isolation. It should no longer leak within your components.
- improvement: stateless component entries no longer require defining a `component/0` function.
- documentation: new [`sandboxing.md`](guides/sandboxing.md) guide.

## v0.2.0 (2022-07-30)

- feature: new tab to browse your component sources
- feature: work-in-progress component documentation tab
- feature: new page entry support, which allows you create custom pages within your storybook
- improvement: introduced `%VariationGroup{}` to render mulitple variations in a single page div.

## v0.1.0 (2022-07-26)

Initial release.
