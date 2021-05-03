[
  import_deps: [:ecto, :phoenix, :stream_data],
  inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{ex,exs}"],
  subdirectories: ["priv/*/migrations"],
  locals_without_parens: [
    middleware: 1,
    middleware: 2,
    register: 2,
    register: 3
  ]
]
