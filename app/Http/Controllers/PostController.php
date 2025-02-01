<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Response;
use Illuminate\View\View;

class PostController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth')->except(['index', 'show']);
    }

    public function index(): View|Response
    {
        $posts = Post::with('user')
            ->where('published', true)
            ->orderBy('published_at', 'desc')
            ->paginate(10);
        
        if (request()->method() === 'HEAD') {
            return response()->view('posts.index', compact('posts'))
                ->header('Content-Length', '0');
        }
        
        return view('posts.index', compact('posts'));
    }

    public function create(): View
    {
        return view('posts.create');
    }

    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'title' => 'required|max:255',
            'content' => 'required',
            'featured_image' => 'nullable|image|max:2048|mimes:jpeg,png,jpg,gif',
        ]);

        try {
            DB::beginTransaction();

            $slug = Str::slug($validated['title']);
            $originalSlug = $slug;
            $counter = 1;

            while (Post::where('slug', $slug)->exists()) {
                $slug = $originalSlug . '-' . $counter++;
            }

            $post = new Post($validated);
            $post->user_id = auth()->id();
            $post->slug = $slug;
            
            if ($request->hasFile('featured_image')) {
                try {
                    $path = $request->file('featured_image')->store('posts', 'public');
                    $post->featured_image = $path;
                } catch (\Exception $e) {
                    DB::rollBack();
                    return redirect()->back()
                        ->withInput()
                        ->withErrors(['featured_image' => 'Failed to upload image. Please try again.']);
                }
            }

            $post->save();
            DB::commit();

            return redirect()->route('posts.show', $post)
                ->with('success', 'Post created successfully.');
        } catch (\Exception $e) {
            DB::rollBack();
            \Log::error('Failed to create post: ' . $e->getMessage());
            
            return redirect()->back()
                ->withErrors(['error' => 'Failed to create post. Please try again.']);
        }
    }

    public function show(Post $post): View|Response
    {
        if (!$post->published && auth()->id() !== $post->user_id) {
            abort(404);
        }

        return view('posts.show', compact('post'));
    }

    public function edit(Post $post): View
    {
        $this->authorize('update', $post);
        return view('posts.edit', compact('post'));
    }

    public function update(Request $request, Post $post): RedirectResponse
    {
        $this->authorize('update', $post);

        $validated = $request->validate([
            'title' => 'required|max:255',
            'content' => 'required',
            'featured_image' => 'nullable|image|max:2048|mimes:jpeg,png,jpg,gif',
        ]);

        try {
            DB::beginTransaction();

            if ($post->title !== $validated['title']) {
                $slug = Str::slug($validated['title']);
                $originalSlug = $slug;
                $counter = 1;

                while (Post::where('slug', $slug)->where('id', '!=', $post->id)->exists()) {
                    $slug = $originalSlug . '-' . $counter++;
                }
                $validated['slug'] = $slug;
            }

            if ($request->hasFile('featured_image')) {
                try {
                    if ($post->featured_image) {
                        Storage::disk('public')->delete($post->featured_image);
                    }
                    
                    $path = $request->file('featured_image')->store('posts', 'public');
                    $post->featured_image = $path;
                } catch (\Exception $e) {
                    DB::rollBack();
                    return redirect()->back()
                        ->withInput()
                        ->withErrors(['featured_image' => 'Failed to upload image. Please try again.']);
                }
            }

            $post->update($validated);
            DB::commit();

            return redirect()->route('posts.show', $post)
                ->with('success', 'Post updated successfully.');
        } catch (\Exception $e) {
            DB::rollBack();
            \Log::error('Failed to update post: ' . $e->getMessage());
            
            return redirect()->back()
                ->withErrors(['error' => 'Failed to update post. Please try again.']);
        }
    }

    public function destroy(Post $post): RedirectResponse
    {
        $this->authorize('delete', $post);
        
        try {
            DB::beginTransaction();

            if ($post->featured_image) {
                try {
                    Storage::disk('public')->delete($post->featured_image);
                } catch (\Exception $e) {
                    \Log::error('Failed to delete post image: ' . $e->getMessage());
                }
            }

            $post->delete();
            DB::commit();

            return redirect()->route('posts.index')
                ->with('success', 'Post deleted successfully.');
        } catch (\Exception $e) {
            DB::rollBack();
            \Log::error('Failed to delete post: ' . $e->getMessage());
            
            return redirect()->back()
                ->withErrors(['error' => 'Failed to delete post. Please try again.']);
        }
    }
}