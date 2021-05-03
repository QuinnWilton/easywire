const colors = require('tailwindcss/colors')

module.exports = {
  purge: {
    enabled: process.env.NODE_ENV === "production",
    content: [
      "../lib/**/*.eex",
      "../lib/**/*.leex",
      "../lib/**/*_view.ex"
    ],
    options: {
      whitelist: [/phx/, /nprogress/]
    }
  },
  theme: {
    extend: {
      colors: {
        cyan: colors.cyan,
      }
    }
  },
  plugins: [
    require('@tailwindcss/forms'),
  ]
}
