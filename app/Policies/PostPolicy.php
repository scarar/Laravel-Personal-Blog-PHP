<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\Post;
use App\Models\User;
use Illuminate\Auth\Access\Response;

class PostPolicy
{
    public function viewAny(?User $user): Response
    {
        return Response::allow();
    }

    public function view(?User $user, Post $post): Response
    {
        if ($post->published) {
            return Response::allow();
        }

        if ($user && $user->id === $post->user_id) {
            return Response::allow();
        }

        return Response::deny('This post is not published.');
    }

    public function create(User $user): Response
    {
        return Response::allow();
    }

    public function update(User $user, Post $post): Response
    {
        return $user->id === $post->user_id
            ? Response::allow()
            : Response::deny('You do not own this post.');
    }

    public function delete(User $user, Post $post): Response
    {
        return $user->id === $post->user_id
            ? Response::allow()
            : Response::deny('You do not own this post.');
    }
}
