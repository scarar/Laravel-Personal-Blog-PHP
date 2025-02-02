@extends('layouts.app')

@section('content')
<div class="space-y-6">
    <!-- Header -->
    <div class="flex justify-between items-center">
        <h1 class="text-3xl font-bold text-gray-900">Blog Posts</h1>
        @auth
            <a href="{{ route('posts.create') }}" class="btn btn-primary">
                New Post
            </a>
        @endauth
    </div>

    <!-- Posts Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        @forelse ($posts as $post)
            <article class="bg-white rounded-lg shadow-md overflow-hidden">
                @if ($post->featured_image)
                    <div class="aspect-w-16 aspect-h-9">
                        <img src="{{ asset('storage/' . $post->featured_image) }}" 
                             alt="{{ $post->title }}" 
                             class="w-full h-48 object-cover">
                    </div>
                @endif
                <div class="p-6">
                    <h2 class="text-xl font-semibold mb-2">
                        <a href="{{ route('posts.show', $post) }}" 
                           class="text-gray-900 hover:text-blue-600 transition duration-150">
                            {{ $post->title }}
                        </a>
                    </h2>
                    
                    @if ($post->excerpt)
                        <p class="text-gray-600 mb-4">{{ $post->excerpt }}</p>
                    @else
                        <p class="text-gray-600 mb-4">
                            {{ Str::limit(strip_tags($post->content), 150) }}
                        </p>
                    @endif

                    <div class="flex justify-between items-center text-sm text-gray-500">
                        <span>By {{ $post->user->name }}</span>
                        <span>{{ $post->created_at->diffForHumans() }}</span>
                    </div>

                    @auth
                        @if (auth()->user()->id === $post->user_id || auth()->user()->isAdmin())
                            <div class="mt-4 pt-4 border-t border-gray-100 flex justify-end space-x-2">
                                <a href="{{ route('posts.edit', $post) }}" 
                                   class="btn btn-secondary text-sm">
                                    Edit
                                </a>
                                <form action="{{ route('posts.destroy', $post) }}" 
                                      method="POST" 
                                      class="inline"
                                      onsubmit="return confirm('Are you sure you want to delete this post?')">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="btn btn-danger text-sm">
                                        Delete
                                    </button>
                                </form>
                            </div>
                        @endif
                    @endauth
                </div>
            </article>
        @empty
            <div class="col-span-full">
                <div class="bg-white rounded-lg shadow-md p-6 text-center text-gray-500">
                    No posts found.
                    @auth
                        <p class="mt-2">
                            <a href="{{ route('posts.create') }}" class="text-blue-600 hover:text-blue-800">
                                Create your first post
                            </a>
                        </p>
                    @endauth
                </div>
            </div>
        @endforelse
    </div>

    <!-- Pagination -->
    @if ($posts->hasPages())
        <div class="mt-8">
            {{ $posts->links() }}
        </div>
    @endif
</div>
@endsection