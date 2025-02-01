<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Support\Facades\Storage;

class Post extends Model
{
    use HasFactory;
    protected $fillable = [
        'title',
        'slug',
        'content',
        'featured_image',
        'published',
        'published_at',
        'user_id'
    ];

    protected $casts = [
        'published' => 'boolean',
        'published_at' => 'datetime'
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function getImageUrlAttribute(): ?string
    {
        return $this->featured_image
            ? Storage::disk('public')->url($this->featured_image)
            : null;
    }

    public function getExcerptAttribute(): string
    {
        return \Str::limit(strip_tags($this->content), 150);
    }

    protected static function boot(): void
    {
        parent::boot();

        static::deleting(function (Post $post) {
            if ($post->featured_image) {
                Storage::disk('public')->delete($post->featured_image);
            }
        });
    }
}
