@extends('layouts.app')

@section('content')
<div class="container mx-auto px-4">
    <div class="bg-white shadow-lg rounded-lg p-6 mb-6">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold">Dashboard</h1>
            <a href="{{ route('posts.create') }}" class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
                Create New Post
            </a>
        </div>

        <!-- Stats Overview -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
            <div class="bg-gray-50 p-4 rounded-lg">
                <h3 class="text-lg font-semibold mb-2">Total Posts</h3>
                <p class="text-3xl font-bold text-blue-600">{{ $totalPosts ?? 0 }}</p>
            </div>
            <div class="bg-gray-50 p-4 rounded-lg">
                <h3 class="text-lg font-semibold mb-2">Published Posts</h3>
                <p class="text-3xl font-bold text-green-600">{{ $publishedPosts ?? 0 }}</p>
            </div>
            <div class="bg-gray-50 p-4 rounded-lg">
                <h3 class="text-lg font-semibold mb-2">Draft Posts</h3>
                <p class="text-3xl font-bold text-yellow-600">{{ $draftPosts ?? 0 }}</p>
            </div>
        </div>

        <!-- Recent Posts -->
        <div class="mb-6">
            <h2 class="text-xl font-semibold mb-4">Your Recent Posts</h2>
            @if(isset($recentPosts) && $recentPosts->count() > 0)
                <div class="space-y-4">
                    @foreach($recentPosts as $post)
                        <div class="border rounded-lg p-4 hover:bg-gray-50">
                            <div class="flex justify-between items-start">
                                <div>
                                    <h3 class="font-semibold">
                                        <a href="{{ route('posts.show', $post) }}" class="text-blue-600 hover:text-blue-800">
                                            {{ $post->title }}
                                        </a>
                                    </h3>
                                    <p class="text-sm text-gray-600">
                                        {{ Str::limit(strip_tags($post->content), 100) }}
                                    </p>
                                    <div class="text-xs text-gray-500 mt-2">
                                        Created {{ $post->created_at->diffForHumans() }}
                                        • Status: 
                                        @if($post->published)
                                            <span class="text-green-600">Published</span>
                                        @else
                                            <span class="text-yellow-600">Draft</span>
                                        @endif
                                    </div>
                                </div>
                                <div class="flex space-x-2">
                                    <a href="{{ route('posts.edit', $post) }}" 
                                       class="text-blue-500 hover:text-blue-700">
                                        Edit
                                    </a>
                                    <form action="{{ route('posts.destroy', $post) }}" method="POST" 
                                          onsubmit="return confirm('Are you sure you want to delete this post?');">
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit" class="text-red-500 hover:text-red-700">
                                            Delete
                                        </button>
                                    </form>
                                </div>
                            </div>
                        </div>
                    @endforeach
                </div>
            @else
                <p class="text-gray-600">No posts yet. Create your first post!</p>
            @endif
        </div>

        <!-- Quick Actions -->
        <div>
            <h2 class="text-xl font-semibold mb-4">Quick Actions</h2>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                <a href="{{ route('posts.create') }}" 
                   class="flex items-center justify-center p-4 bg-blue-50 rounded-lg hover:bg-blue-100">
                    <span class="text-blue-700">New Post</span>
                </a>
                <a href="{{ route('posts.index') }}" 
                   class="flex items-center justify-center p-4 bg-green-50 rounded-lg hover:bg-green-100">
                    <span class="text-green-700">View Blog</span>
                </a>
                <a href="#" 
                   class="flex items-center justify-center p-4 bg-purple-50 rounded-lg hover:bg-purple-100">
                    <span class="text-purple-700">Profile Settings</span>
                </a>
                <a href="#" 
                   class="flex items-center justify-center p-4 bg-gray-50 rounded-lg hover:bg-gray-100">
                    <span class="text-gray-700">Help & Support</span>
                </a>
            </div>
        </div>
    </div>
</div>
@endsection