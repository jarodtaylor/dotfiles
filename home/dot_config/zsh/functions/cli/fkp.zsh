# fkp - Find Kill Port: Interactive port and process management
#
# Tags: port, process, kill, network, lsof, fzf, development, server
#
# Purpose: Find processes using network ports and interactively kill them
# Usage: fkp [port-number]
#
# Features:
# - Lists all processes using network ports
# - Interactive selection with process details preview
# - Safe process termination with confirmation
# - Optional port filtering for quick searches
# - Shows PID, process name, port, protocol, and connection state
#
# Examples:
#   fkp              # Show all processes using ports
#   fkp 3000         # Show only processes using port 3000
#   fkp 5173         # Show only processes using port 5173 (Vite dev server)
#   fkp 8080         # Show only processes using port 8080
#
# Common development ports:
#   3000, 3001       # React, Node.js dev servers
#   5173, 5174       # Vite dev servers
#   8000, 8080       # Various web servers
#   4200             # Angular dev server
#   9000, 9001       # Various development tools
#
# Dependencies: lsof, fzf, ps

fkp() {
  local port_filter=""
  local header_text="🔍 All network processes"

  # If port number provided, filter by that port
  if [ -n "$1" ]; then
    port_filter=":$1"
    header_text="🔍 Processes using port $1"
  fi

  # Get processes using network ports with simpler parsing
  local result
  result=$(
    # Get TCP connections (most common for web servers)
    lsof -i TCP$port_filter -P -n 2>/dev/null |
    awk 'NR > 1 {
      # Extract basic info: COMMAND PID USER ... NAME
      cmd = $1
      pid = $2
      user = $3
      name = $9

      # Simple port extraction - just get the number after the last colon
      split(name, parts, ":")
      port = parts[length(parts)]
      # Remove any parentheses like (LISTEN)
      gsub(/\(.*\)/, "", port)

      # Format for display
      printf "%-15s %8s %-12s %6s %s\n", cmd, pid, user, port, name
    }' |
    sort -k4 -n | # Sort by port number
    fzf --ansi \
        --prompt "🎯 Select process to kill > " \
        --header "$header_text | CTRL-R (refresh) • CTRL-/ (toggle preview) • ESC (cancel)" \
        --header-lines=0 \
        --preview '
          pid=$(echo {} | awk "{print \$2}")
          cmd=$(echo {} | awk "{print \$1}")
          port=$(echo {} | awk "{print \$4}")

          if [ -n "$pid" ] && [ "$pid" != "PID" ]; then
            echo "🔍 Process Details"
            echo "═══════════════════════════════════════"
            echo "📋 Command: $cmd"
            echo "🆔 PID: $pid"
            echo "🌐 Port: $port"
            echo ""

            echo "💻 System Info:"
            ps -p $pid -o pid,user,%cpu,%mem,command --no-headers 2>/dev/null || echo "Process not found"
            echo ""

            echo "💡 Quick Actions:"
            echo "   • Select and choose option 1 for graceful kill"
            echo "   • Select and choose option 2 for force kill"
            echo ""
            echo "💭 Tip: This will free up port $port for your dev server"
          else
            echo "Select a process to see details"
          fi
        ' \
        --preview-window 'right,50%,border-left' \
        --bind 'ctrl-/:change-preview-window(down|hidden|)' \
        --bind 'ctrl-r:reload(lsof -i TCP'$port_filter' -P -n 2>/dev/null | awk "NR > 1 { cmd = \$1; pid = \$2; user = \$3; name = \$9; split(name, parts, \":\"); port = parts[length(parts)]; gsub(/\\(.*\\)/, \"\", port); printf \"%-15s %8s %-12s %6s %s\\n\", cmd, pid, user, port, name }" | sort -k4 -n)'
  )

  # Handle cancellation
  if [ -z "$result" ]; then
    echo "❌ No process selected."
    return 0
  fi

  # Parse selected result
  local process_name pid user port connection
  process_name=$(echo "$result" | awk '{print $1}')
  pid=$(echo "$result" | awk '{print $2}')
  user=$(echo "$result" | awk '{print $3}')
  port=$(echo "$result" | awk '{print $4}')
  connection=$(echo "$result" | awk '{for(i=5;i<=NF;i++) printf "%s ", $i; print ""}')

  # Safety check
  if [ -z "$pid" ] || ! [[ "$pid" =~ ^[0-9]+$ ]]; then
    echo "❌ Error: Invalid PID selected"
    return 1
  fi

  # Show selection and confirm
  echo ""
  echo "🎯 Selected Process:"
  echo "   📋 Process: $process_name"
  echo "   🆔 PID: $pid"
  echo "   👤 User: $user"
  echo "   🌐 Port: $port"
  echo "   🔗 Connection: $connection"
  echo ""

  # Interactive confirmation with options
  echo "⚡ Actions:"
  echo "   [1] 🛑 Kill process (SIGTERM - graceful shutdown)"
  echo "   [2] ⚡ Force kill (SIGKILL - immediate termination)"
  echo "   [3] 🔍 Show detailed process info"
  echo "   [4] ❌ Cancel"
  echo -n "Choose an option [1-4]: "
  read choice

  case "$choice" in
    1)
      echo "🛑 Sending SIGTERM to process $pid ($process_name)..."
      if kill "$pid" 2>/dev/null; then
        echo "✅ Process terminated successfully"
        # Wait a moment and check if it's really gone
        sleep 1
        if ! kill -0 "$pid" 2>/dev/null; then
          echo "✅ Process $pid is no longer running"
          echo "💡 Port $port should now be available"
        else
          echo "⚠️  Process $pid is still running (may be cleaning up)"
        fi
      else
        echo "❌ Failed to terminate process (may already be dead or insufficient permissions)"
      fi
      ;;
    2)
      echo "⚡ Force killing process $pid ($process_name)..."
      if kill -9 "$pid" 2>/dev/null; then
        echo "✅ Process force killed"
        echo "💡 Port $port should now be available"
      else
        echo "❌ Failed to kill process (may already be dead or insufficient permissions)"
      fi
      ;;
    3)
      echo ""
      echo "🔍 Detailed Process Information"
      echo "═══════════════════════════════════════"
      ps -p "$pid" -o pid,ppid,user,cpu,pmem,vsz,rss,tty,stat,lstart,time,command 2>/dev/null || echo "Process not found"
      echo ""
      echo "🌐 All Network Connections:"
      lsof -p "$pid" -i 2>/dev/null || echo "No network connections found"
      ;;
    *)
      echo "❌ Cancelled."
      ;;
  esac
}
