# Laravel Personal Blog

A personal blog built with Laravel PHP framework. This application allows users to create, read, update, and delete blog posts with features like authentication, image uploads, and markdown support.

## Features

- User authentication
- Create, edit, and delete blog posts
- Featured image upload
- Responsive design with Tailwind CSS
- Clean and modern UI
- Authorization using Laravel policies

## Requirements

- PHP >= 8.2
- Composer
- SQLite or MySQL/PostgreSQL
- Node.js & NPM (for frontend assets)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/scarar/Laravel-Personal-Blog-PHP.git
   cd Laravel-Personal-Blog-PHP
   ```

2. Install dependencies:
   ```bash
   composer install
   ```

3. Set up environment file:
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```

4. Configure database in .env file:
   ```
   DB_CONNECTION=sqlite
   ```

5. Run migrations:
   ```bash
   php artisan migrate
   ```

6. Create storage link:
   ```bash
   php artisan storage:link
   ```

7. Start the development server:
   ```bash
   php artisan serve
   ```

## License

This project is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
