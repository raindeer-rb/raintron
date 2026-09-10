# frozen_string_literal: true

class Layout < LowNode
  def render
    <html>
      <head>
        <meta charset="UTF-8">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
        <link rel="stylesheet" href="/style.css">
      </head>
      <body>
        <header>
          <div class="container">
            <a href="/"><span id="logo">{"Site Name"}</span></a>
            <nav id="main-menu">
              <ul>
                <li><a href="/docs">{"Docs"}</a></li>
                <li><a href="https://github.com/raindeer-rb/raindeer">{"Source"}</a></li>
              </ul>
            </nav>
          </div>
        </header>

        <div class="container overflow-auto">
          <main id="content">
            <{ :slot }>
          </main>
        </div>

        <footer>
          <div class="container">
            <ul>
              <li><a href="https://reddit.com/r/raindeer">{"Reddit"}</a></li>
              <li><a href="https://discord.gg/UBex4JQgnX">{"Discord"}</a></li>
              <li><a href="https://www.rubyforum.org/tag/raindeer/97">{"Forum"}</a></li>
              <li><a href="https://github.com/raindeer-rb/raindeer">{"GitHub"}</a></li>
            </ul>
          </div>
        </footer>
      </body>
    </html>
  end
end
