# frozen_string_literal: true

class HomeNode < LowNode
  observe '/'

  def render
    <{ Layout: }>
      <h1>{"Welcome to Raindeer"}</h1>

      <p>{"Find me in '/app/home_node.rb'."}</p>
    <{ :Layout }>
  end
end
