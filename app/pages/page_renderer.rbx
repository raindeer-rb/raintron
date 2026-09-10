# frozen_string_literal: true

class PageRenderer < LowNode
  observe '/*'

  def initialize(event:)
    page = Raindeer.pages.page(path: event.route.path) || return

    @html = page.html
    @title = page.metadata[:title]
    @published = @html && page.metadata[:published]
  end

  def render(event:)
    <{ if: @published }>
      <{ Layout: }>
        <h1>{@title}</h1>

        <{ @html }>
      <{ :Layout }>
    <{ :if }>
  end
end
