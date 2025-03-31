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

run "mkdir -p app/assets/config"
file "app/assets/config/manifest.js", <<~JS
  //= link_tree ../images
  //= link_directory ../stylesheets .css
JS

after_bundle do
  rails_command "db:drop db:create db:migrate"
  generate("simple_form:install")
  generate(:controller, "pages", "home", "--skip-routes", "--no-test-framework")
  route 'root to: "pages#home"'

  append_file ".gitignore", <<~TXT
    .env*
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

  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: "development"
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: "production"

  run "bundle lock --add-platform x86_64-linux"
  run "touch .env"

  readme_content = <<~MARKDOWN
    # 🚀 Certification — Ruby on Rails App (No Bootstrap)

    Ce projet a été généré avec un template personnalisé sans Bootstrap.

    ## Stack

    - Ruby on Rails 7
    - PostgreSQL
    - Devise
    - Simple Form
    - Dotenv
    - Importmap

    ## Setup

    ```bash
    bundle install
    rails db:create db:migrate
    rails s
    ```

    ## Déploiement

    - Préparé pour Heroku (`bundle lock --add-platform x86_64-linux`)
    - Fichier `.env` prêt à l’emploi
    - Config devise + page home
  MARKDOWN

  file "README.md", readme_content, force: true

  git :init
  git add: "."
  git commit: "-m 'Initial commit: Devise + SimpleForm (no Bootstrap)'"

  say "✅ Projet prêt sans Bootstrap, avec Devise, SimpleForm, .env et README", :green
  say "👉 Prochaine étape : rails s ou rails db:create si pas encore fait", :blue
end
