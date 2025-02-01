<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ config('app.name', 'Laravel Blog') }}</title>
    <link rel="stylesheet" href="{{ asset('css/app.css') }}">
</head>
<body class="bg-gray-100">
    <nav class="bg-white shadow-lg">
        <div class="max-w-6xl mx-auto px-4">
            <div class="flex justify-between">
                <div class="flex space-x-7">
                    <div>
                        <a href="{{ url('/') }}" class="flex items-center py-4 px-2">
                            <span class="font-semibold text-gray-500 text-lg">{{ config('app.name', 'Laravel Blog') }}</span>
                        </a>
                    </div>
                </div>
                <div class="flex items-center space-x-3">
                    @guest
                        <a href="{{ route('login') }}" class="py-2 px-4 text-gray-500 hover:text-gray-700">Login</a>
                        <a href="{{ route('register') }}" class="py-2 px-4 bg-blue-500 text-white rounded hover:bg-blue-600">Register</a>
                    @else
                        <a href="{{ route('posts.create') }}" class="py-2 px-4 bg-green-500 text-white rounded hover:bg-green-600">New Post</a>
                        <form method="POST" action="{{ route('logout') }}">
                            @csrf
                            <button type="submit" class="py-2 px-4 text-gray-500 hover:text-gray-700">Logout</button>
                        </form>
                    @endguest
                </div>
            </div>
        </div>
    </nav>

    <main class="py-8">
        <div class="max-w-6xl mx-auto px-4">
            @if (session('success'))
                <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative mb-4">
                    {{ session('success') }}
                </div>
            @endif

            @yield('content')
        </div>
    </main>
</body>
</html>