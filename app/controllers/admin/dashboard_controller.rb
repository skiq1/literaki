module Admin
  class DashboardController < ApplicationController
    def index
      render html: page("Literaki Admin", dashboard_html).html_safe
    end

    def show_game
      game = Game.includes(:moves, game_players: :user).find(params[:id])

      render html: page("Game ##{game.id}", game_html(game)).html_safe
    end

    private

    def page(title, body)
      <<~HTML
        <!doctype html>
        <html lang="pl">
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>#{escape(title)}</title>
            <style>
              :root { color-scheme: light; --border: #d8dee4; --muted: #57606a; --bg: #f6f8fa; --text: #24292f; --accent: #0969da; }
              * { box-sizing: border-box; }
              body { margin: 0; font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; color: var(--text); background: #fff; }
              header { border-bottom: 1px solid var(--border); background: var(--bg); }
              main, .bar { max-width: 1180px; margin: 0 auto; padding: 24px; }
              .bar { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding-top: 18px; padding-bottom: 18px; }
              h1 { margin: 0; font-size: 22px; }
              h2 { margin: 28px 0 12px; font-size: 16px; }
              a { color: var(--accent); text-decoration: none; }
              a:hover { text-decoration: underline; }
              .grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 12px; }
              .stat { border: 1px solid var(--border); border-radius: 8px; padding: 14px; background: #fff; }
              .stat strong { display: block; font-size: 26px; line-height: 1.1; margin-top: 6px; }
              .muted { color: var(--muted); font-size: 13px; }
              table { width: 100%; border-collapse: collapse; border: 1px solid var(--border); border-radius: 8px; overflow: hidden; }
              th, td { padding: 10px 12px; border-bottom: 1px solid var(--border); text-align: left; vertical-align: top; font-size: 14px; }
              th { background: var(--bg); font-weight: 650; }
              tr:last-child td { border-bottom: 0; }
              code, pre { font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; font-size: 12px; }
              pre { overflow: auto; border: 1px solid var(--border); border-radius: 8px; padding: 12px; background: var(--bg); }
              .badge { display: inline-block; border: 1px solid var(--border); border-radius: 999px; padding: 2px 8px; font-size: 12px; background: var(--bg); }
              .board { display: grid; grid-template-columns: repeat(15, 28px); width: max-content; border: 1px solid var(--border); }
              .cell { width: 28px; height: 28px; display: grid; place-items: center; border-right: 1px solid var(--border); border-bottom: 1px solid var(--border); font-size: 13px; font-weight: 700; }
              .cell:nth-child(15n) { border-right: 0; }
              .cell:nth-last-child(-n + 15) { border-bottom: 0; }
              @media (max-width: 760px) {
                main, .bar { padding: 16px; }
                .grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
                table { display: block; overflow-x: auto; white-space: nowrap; }
                .board { grid-template-columns: repeat(15, 22px); }
                .cell { width: 22px; height: 22px; font-size: 11px; }
              }
            </style>
          </head>
          <body>
            <header>
              <div class="bar">
                <h1>#{escape(title)}</h1>
                <nav><a href="/admin">Dashboard</a> <span class="muted">/</span> <a href="/api/v1/games">API</a></nav>
              </div>
            </header>
            <main>#{body}</main>
          </body>
        </html>
      HTML
    end

    def dashboard_html
      <<~HTML
        #{stats_html}
        <h2>Games</h2>
        #{games_table(Game.includes(:winner, :current_turn_user, game_players: :user).order(created_at: :desc).limit(50))}
        <h2>Users</h2>
        #{users_table(User.order(created_at: :desc).limit(50))}
        <h2>Words</h2>
        #{words_table(Word.order(:language, :value).limit(100))}
      HTML
    end

    def stats_html
      <<~HTML
        <section class="grid">
          #{stat("Users", User.count)}
          #{stat("Games", Game.count)}
          #{stat("Active games", Game.where(status: "active").count)}
          #{stat("Moves", Move.count)}
        </section>
      HTML
    end

    def stat(label, value)
      %(<div class="stat"><span class="muted">#{escape(label)}</span><strong>#{escape(value)}</strong></div>)
    end

    def users_table(users)
      rows = users.map do |user|
        <<~HTML
          <tr>
            <td>#{user.id}</td>
            <td>#{escape(user.username)}</td>
            <td><code>#{escape(user.api_token)}</code></td>
            <td>#{user.games_played}</td>
            <td>#{user.games_won}</td>
            <td>#{user.total_score}</td>
          </tr>
        HTML
      end.join

      table(%w[ID Username Token Played Won Score], rows)
    end

    def games_table(games)
      rows = games.map do |game|
        players = game.game_players.map { |player| "#{player.position}. #{player.user.username} (#{player.score})" }.join("<br>")

        <<~HTML
          <tr>
            <td><a href="/admin/games/#{game.id}">##{game.id}</a></td>
            <td><span class="badge">#{escape(game.status)}</span></td>
            <td>#{players}</td>
            <td>#{escape(game.current_turn_user&.username || "-")}</td>
            <td>#{escape(game.winner&.username || "-")}</td>
            <td>#{game.moves.size}</td>
            <td>#{escape(game.created_at&.iso8601)}</td>
          </tr>
        HTML
      end.join

      table(["ID", "Status", "Players", "Turn", "Winner", "Moves", "Created"], rows)
    end

    def words_table(words)
      rows = words.map do |word|
        <<~HTML
          <tr>
            <td>#{word.id}</td>
            <td>#{escape(word.value)}</td>
            <td>#{escape(word.language)}</td>
          </tr>
        HTML
      end.join

      table(%w[ID Value Language], rows)
    end

    def game_html(game)
      <<~HTML
        <p><a href="/admin">&larr; Back to dashboard</a></p>
        <section class="grid">
          #{stat("Status", game.status)}
          #{stat("Current turn", game.current_turn_user&.username || "-")}
          #{stat("Winner", game.winner&.username || "-")}
          #{stat("Bag tiles", game.bag.size)}
        </section>
        <h2>Players</h2>
        #{game_players_table(game)}
        <h2>Board</h2>
        #{board_html(game.board)}
        <h2>Moves</h2>
        #{moves_table(game.moves.order(:created_at))}
        <h2>Raw State</h2>
        <pre>#{escape(JSON.pretty_generate(GameSerializer.new(game, current_user: game.users.first || User.new).as_json))}</pre>
      HTML
    end

    def game_players_table(game)
      rows = game.game_players.map do |player|
        <<~HTML
          <tr>
            <td>#{player.position}</td>
            <td>#{player.user_id}</td>
            <td>#{escape(player.user.username)}</td>
            <td>#{player.score}</td>
            <td><code>#{escape(player.rack.join(" "))}</code></td>
            <td>#{player.passed_turns_count}</td>
          </tr>
        HTML
      end.join

      table(["Position", "User ID", "Username", "Score", "Rack", "Passes"], rows)
    end

    def moves_table(moves)
      rows = moves.map do |move|
        <<~HTML
          <tr>
            <td>#{move.id}</td>
            <td>#{move.user_id}</td>
            <td><span class="badge">#{escape(move.move_type)}</span></td>
            <td>#{move.score}</td>
            <td><code>#{escape(move.tiles.to_json)}</code></td>
            <td>#{escape(move.created_at&.iso8601)}</td>
          </tr>
        HTML
      end.join

      table(["ID", "User ID", "Type", "Score", "Tiles", "Created"], rows)
    end

    def board_html(board)
      cells = 15.times.flat_map do |y|
        15.times.map do |x|
          letter = board["#{x},#{y}"]
          %(<div class="cell">#{escape(letter)}</div>)
        end
      end.join

      %(<div class="board">#{cells}</div>)
    end

    def table(headers, rows)
      head = headers.map { |header| "<th>#{escape(header)}</th>" }.join
      body = rows.presence || %(<tr><td colspan="#{headers.size}" class="muted">No data</td></tr>)

      "<table><thead><tr>#{head}</tr></thead><tbody>#{body}</tbody></table>"
    end

    def escape(value)
      ERB::Util.html_escape(value.to_s)
    end
  end
end
