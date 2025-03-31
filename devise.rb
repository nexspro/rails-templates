# no_bootstrap.rb

inject_into_file "Gemfile", before: "group :development, :test do" do
  <<~RUBY
    gem "devise"
    gem "simple_form"
    gem "autoprefixer-rails"
    gem "font-awesome-sass", "~> 6.1"
    gem "dotenv-rails"
    gem "sassc-rails"
  RUBY
end

after_bundle do
  rails_command "db:drop db:create db:migrate"

  generate("simple_form:install") # ❌ no --bootstrap
  generate(:controller, "pages", "home", "--skip-routes", "--no-test-framework")

  route 'root to: "pages#home"'

  append_file ".gitignore", <<~TXT
    # Ignore .env file containing credentials.
    .env*

    # Ignore system files
    *.swp
    .DS_Store
  TXT

  generate("devise:install")
  generate("devise", "User")

  run "rm app/controllers/application_controller.rb"
  file "app/controllers/application_controller.rb", <<~RUBY
    class ApplicationController < ActionController::Base
      before_action :authenticate_user!
    end
  RUBY

  rails_command "db:migrate"
  generate("devise:views")

  run "rm app/controllers/pages_controller.rb"
  file "app/controllers/pages_controller.rb", <<~RUBY
    class PagesController < ApplicationController
      skip_before_action :authenticate_user!, only: [ :home ]

      def home
      end
    end
  RUBY

  # Dev / Prod mailer
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: "development"
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: "production"

  # Heroku platform
  run "bundle lock --add-platform x86_64-linux"

  # Dotenv
  run "touch .env"

  # Rubocop (optionnel)
  run "curl -L https://raw.githubusercontent.com/lewagon/rails-templates/master/.rubocop.yml > .rubocop.yml"

  git :init
  git add: "."
  git commit: "-m 'Initial commit: Devise + SimpleForm (no Bootstrap)'"

  say "✅ Projet prêt sans Bootstrap, avec Devise, SimpleForm et .env", :green
  say "👉 Prochaine étape : rails s ou rails db:create si pas encore fait", :blue
end
