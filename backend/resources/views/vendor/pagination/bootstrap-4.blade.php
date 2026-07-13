@if ($paginator->hasPages())
<div class="pager-btns">
    {{-- Previous Page Link --}}
    @if ($paginator->onFirstPage())
    <span class="pager-btn" aria-disabled="true">&lsaquo;</span>
    @else
    <a class="pager-btn" href="{{ $paginator->previousPageUrl() }}" rel="prev">&lsaquo;</a>
    @endif

    {{-- Pagination Elements --}}
    @foreach ($elements as $element)
        @if (is_string($element))
        <span class="pager-btn" aria-disabled="true">{{ $element }}</span>
        @endif

        @if (is_array($element))
            @foreach ($element as $page => $url)
                @if ($page == $paginator->currentPage())
                <span class="pager-btn active">{{ $page }}</span>
                @else
                <a class="pager-btn" href="{{ $url }}">{{ $page }}</a>
                @endif
            @endforeach
        @endif
    @endforeach

    {{-- Next Page Link --}}
    @if ($paginator->hasMorePages())
    <a class="pager-btn" href="{{ $paginator->nextPageUrl() }}" rel="next">&rsaquo;</a>
    @else
    <span class="pager-btn" aria-disabled="true">&rsaquo;</span>
    @endif
</div>
@endif
