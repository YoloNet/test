#!/bin/bash

# Enhanced connection monitoring script with real IP support and byte conversion
# Compatible with Caddy reverse proxy setup

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="/var/log/websocket-proxy.log"
DB_FILE="/var/log/websocket-connections.db"
SSH_LOG="/var/log/auth.log"
SECURE_LOG="/var/log/secure"

# Function to convert bytes to human readable format
convert_bytes() {
    local bytes=$1
    if [ -z "$bytes" ] || [ "$bytes" = "NULL" ] || [ "$bytes" -eq 0 ] 2>/dev/null; then
        echo "0 B"
        return
    fi
    
    # Remove any non-numeric characters
    bytes=$(echo "$bytes" | sed 's/[^0-9]//g')
    
    if [ -z "$bytes" ] || [ "$bytes" -eq 0 ] 2>/dev/null; then
        echo "0 B"
        return
    fi
    
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes} B"
    elif [ "$bytes" -lt 1048576 ]; then
        printf "%.1f KB" $(echo "scale=1; $bytes/1024" | bc 2>/dev/null || echo "0")
    elif [ "$bytes" -lt 1073741824 ]; then
        printf "%.1f MB" $(echo "scale=1; $bytes/1048576" | bc 2>/dev/null || echo "0")
    else
        printf "%.2f GB" $(echo "scale=2; $bytes/1073741824" | bc 2>/dev/null || echo "0")
    fi
}

# Function to format bandwidth display
format_bandwidth() {
    local bytes_in=$1
    local bytes_out=$2
    local in_readable=$(convert_bytes "$bytes_in")
    local out_readable=$(convert_bytes "$bytes_out")
    echo "↓${in_readable}/↑${out_readable}"
}

# Function to get current IP
get_server_ip() {
    MYIP=$(curl -s ipinfo.io/ip 2>/dev/null || curl -s ipv4.icanhazip.com 2>/dev/null || curl -s ifconfig.me 2>/dev/null)
    echo ${MYIP:-"Unknown"}
}

# Function to check if database exists
check_database() {
    if [ ! -f "$DB_FILE" ]; then
        echo -e "${RED}Database file not found: $DB_FILE${NC}"
        echo "Make sure the enhanced WebSocket proxy is running first."
        return 1
    fi
    return 0
}

# Function to show WebSocket proxy connections with converted bytes
show_websocket_connections() {
    echo -e "${CYAN}=== WebSocket Proxy Real IP Connections ===${NC}"
    echo -e "${YELLOW}Real IP Address    | Type      | Timestamp           | Data Transfer       | Duration | User Agent${NC}"
    echo "---------------------------------------------------------------------------------------------------------------"
    
    if check_database; then
        sqlite3 "$DB_FILE" "
        SELECT 
            real_ip,
            connection_type,
            timestamp,
            COALESCE(bytes_received, 0),
            COALESCE(bytes_sent, 0),
            duration,
            user_agent
        FROM connections 
        WHERE timestamp > datetime('now', '-24 hours')
        ORDER BY timestamp DESC 
        LIMIT 20;
        " | while IFS='|' read -r real_ip conn_type timestamp bytes_rx bytes_tx duration user_agent; do
            # Format the bandwidth display
            bandwidth_display=$(format_bandwidth "$bytes_rx" "$bytes_tx")
            
            # Truncate user agent if too long
            user_agent_short=$(echo "$user_agent" | cut -c1-25)
            if [ ${#user_agent} -gt 25 ]; then
                user_agent_short="${user_agent_short}.."
            fi
            
            printf "%-18s | %-9s | %-19s | %-19s | %4ss | %s\n" \
                "$real_ip" "$conn_type" "$timestamp" "$bandwidth_display" "$duration" "$user_agent_short"
        done
    else
        echo -e "${RED}No WebSocket connection data available${NC}"
    fi
    echo ""
}

# Function to show active WebSocket connections with bandwidth
show_active_websocket() {
    echo -e "${GREEN}=== Active WebSocket Connections (Last 10 minutes) ===${NC}"
    
    if check_database; then
        ACTIVE_COUNT=$(sqlite3 "$DB_FILE" "
        SELECT COUNT(*) FROM connections 
        WHERE timestamp > datetime('now', '-10 minutes') AND status = 'active'
        ")
        
        echo -e "${BLUE}Active connections: $ACTIVE_COUNT${NC}"
        
        if [ "$ACTIVE_COUNT" -gt 0 ]; then
            echo -e "${YELLOW}Real IP Address    | Type      | Connected Since     | Data Transfer${NC}"
            echo "--------------------------------------------------------------------------------"
            sqlite3 "$DB_FILE" "
            SELECT 
                real_ip,
                connection_type,
                timestamp,
                COALESCE(bytes_received, 0),
                COALESCE(bytes_sent, 0)
            FROM connections 
            WHERE timestamp > datetime('now', '-10 minutes') AND status = 'active'
            ORDER BY timestamp DESC;
            " | while IFS='|' read -r real_ip conn_type timestamp bytes_rx bytes_tx; do
                bandwidth_display=$(format_bandwidth "$bytes_rx" "$bytes_tx")
                printf "%-18s | %-9s | %-19s | %s\n" \
                    "$real_ip" "$conn_type" "$timestamp" "$bandwidth_display"
            done
        fi
    fi
    echo ""
}

# Function to show connection statistics with converted bytes
show_connection_stats() {
    echo -e "${PURPLE}=== Connection Statistics (Last 24 Hours) ===${NC}"
    
    if check_database; then
        echo -e "${YELLOW}Connection Type Statistics:${NC}"
        echo "Type      | Connections | Total Data Transfer"
        echo "----------|-------------|--------------------"
        sqlite3 "$DB_FILE" "
        SELECT 
            connection_type,
            COUNT(*) as total_connections,
            COALESCE(SUM(bytes_sent), 0) + COALESCE(SUM(bytes_received), 0) as total_bytes
        FROM connections 
        WHERE timestamp > datetime('now', '-24 hours')
        GROUP BY connection_type
        ORDER BY total_connections DESC;
        " | while IFS='|' read -r conn_type total_conn total_bytes; do
            total_readable=$(convert_bytes "$total_bytes")
            printf "%-9s | %11s | %s\n" "$conn_type" "$total_conn" "$total_readable"
        done
        
        echo ""
        echo -e "${YELLOW}Top Real IP Addresses by Data Usage:${NC}"
        echo "IP Address         | Connections | Total Data Transfer | Last Seen"
        echo "-------------------|-------------|---------------------|-------------------"
        sqlite3 "$DB_FILE" "
        SELECT 
            real_ip,
            COUNT(*) as connections,
            COALESCE(SUM(bytes_sent), 0) + COALESCE(SUM(bytes_received), 0) as total_bytes,
            MAX(timestamp) as last_seen
        FROM connections 
        WHERE timestamp > datetime('now', '-24 hours')
        GROUP BY real_ip
        ORDER BY total_bytes DESC
        LIMIT 10;
        " | while IFS='|' read -r real_ip connections total_bytes last_seen; do
            total_readable=$(convert_bytes "$total_bytes")
            printf "%-18s | %11s | %-19s | %s\n" \
                "$real_ip" "$connections" "$total_readable" "$last_seen"
        done
    fi
    echo ""
}

# Function to show traditional SSH connections (unchanged)
show_ssh_connections() {
    # Determine which log file to use
    if [ -e "$SSH_LOG" ]; then
        LOG="$SSH_LOG"
    elif [ -e "$SECURE_LOG" ]; then
        LOG="$SECURE_LOG"
    else
        echo -e "${RED}No SSH log files found${NC}"
        return
    fi

    echo -e "${CYAN}=== Traditional SSH Connections ===${NC}"
    
    # Dropbear connections
    data=($(ps aux | grep -i dropbear | awk '{print $2}' 2>/dev/null))
    if [ ${#data[@]} -gt 0 ]; then
        echo -e "${YELLOW}--- Dropbear User Login ---${NC}"
        echo "PID  | Username  | IP Address"
        echo "------------------------------"
        cat "$LOG" | grep -i dropbear | grep -i "Password auth succeeded" > /tmp/login-db.txt 2>/dev/null
        for PID in "${data[@]}"; do
            if [[ "$PID" =~ ^[0-9]+$ ]]; then
                cat /tmp/login-db.txt | grep "dropbear\[$PID\]" > /tmp/login-db-pid.txt 2>/dev/null
                NUM=$(cat /tmp/login-db-pid.txt | wc -l)
                if [ $NUM -eq 1 ]; then
                    USER=$(cat /tmp/login-db-pid.txt | awk '{print $10}')
                    IP=$(cat /tmp/login-db-pid.txt | awk '{print $12}')
                    echo "$PID - $USER - $IP"
                fi
            fi
        done
        echo ""
    fi

    # OpenSSH connections
    echo -e "${YELLOW}--- OpenSSH User Login ---${NC}"
    echo "PID  | Username  | IP Address"
    echo "------------------------------"
    cat "$LOG" | grep -i sshd | grep -i "Accepted password for" > /tmp/login-db.txt 2>/dev/null
    data=($(ps aux | grep "\[priv\]" | sort -k 72 | awk '{print $2}' 2>/dev/null))

    for PID in "${data[@]}"; do
        if [[ "$PID" =~ ^[0-9]+$ ]]; then
            cat /tmp/login-db.txt | grep "sshd\[$PID\]" > /tmp/login-db-pid.txt 2>/dev/null
            NUM=$(cat /tmp/login-db-pid.txt | wc -l)
            if [ $NUM -eq 1 ]; then
                USER=$(cat /tmp/login-db-pid.txt | awk '{print $9}')
                IP=$(cat /tmp/login-db-pid.txt | awk '{print $11}')
                echo "$PID - $USER - $IP"
            fi
        fi
    done
    echo ""
}

# Function to show OpenVPN connections with bandwidth conversion
show_openvpn_connections() {
    echo -e "${CYAN}=== OpenVPN Connections ===${NC}"
    
    # OpenVPN TCP
    if [ -f "/etc/openvpn/server/openvpn-tcp.log" ]; then
        echo -e "${YELLOW}--- OpenVPN TCP User Login ---${NC}"
        echo "Username       | IP Address      | Connected Since     | Data Transfer"
        echo "---------------|-----------------|---------------------|------------------"
        
        # Parse OpenVPN log with bandwidth data
        cat /etc/openvpn/server/openvpn-tcp.log | grep -w "^CLIENT_LIST" | while IFS=',' read -r type username real_ip virtual_ip bytes_rx bytes_tx connected_since connected_since_time; do
            if [ "$type" = "CLIENT_LIST" ] && [ "$username" != "HEADER" ] && [ -n "$username" ]; then
                # Convert bytes to readable format
                bytes_rx_clean=$(echo "$bytes_rx" | sed 's/[^0-9]//g')
                bytes_tx_clean=$(echo "$bytes_tx" | sed 's/[^0-9]//g')
                bandwidth_display=$(format_bandwidth "$bytes_rx_clean" "$bytes_tx_clean")
                
                printf "%-14s | %-15s | %-19s | %s\n" \
                    "$username" "$real_ip" "$connected_since" "$bandwidth_display"
            fi
        done 2>/dev/null
        echo ""
    fi

    # OpenVPN UDP
    if [ -f "/etc/openvpn/server/openvpn-udp.log" ]; then
        echo -e "${YELLOW}--- OpenVPN UDP User Login ---${NC}"
        echo "Username       | IP Address      | Connected Since     | Data Transfer"
        echo "---------------|-----------------|---------------------|------------------"
        
        # Parse OpenVPN log with bandwidth data
        cat /etc/openvpn/server/openvpn-udp.log | grep -w "^CLIENT_LIST" | while IFS=',' read -r type username real_ip virtual_ip bytes_rx bytes_tx connected_since connected_since_time; do
            if [ "$type" = "CLIENT_LIST" ] && [ "$username" != "HEADER" ] && [ -n "$username" ]; then
                # Convert bytes to readable format
                bytes_rx_clean=$(echo "$bytes_rx" | sed 's/[^0-9]//g')
                bytes_tx_clean=$(echo "$bytes_tx" | sed 's/[^0-9]//g')
                bandwidth_display=$(format_bandwidth "$bytes_rx_clean" "$bytes_tx_clean")
                
                printf "%-14s | %-15s | %-19s | %s\n" \
                    "$username" "$real_ip" "$connected_since" "$bandwidth_display"
            fi
        done 2>/dev/null
        echo ""
    fi
}

# Function to show real-time WebSocket logs (unchanged)
show_realtime_logs() {
    echo -e "${GREEN}=== Real-time WebSocket Proxy Logs ===${NC}"
    echo "Press Ctrl+C to stop..."
    echo ""
    
    if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE" | while read line; do
            # Colorize log entries based on content
            if [[ $line == *"NEW_CONNECTION"* ]]; then
                echo -e "${GREEN}$line${NC}"
            elif [[ $line == *"ERROR"* ]]; then
                echo -e "${RED}$line${NC}"
            elif [[ $line == *"WebSocket"* ]]; then
                echo -e "${BLUE}$line${NC}"
            elif [[ $line == *"HTTP"* ]]; then
                echo -e "${YELLOW}$line${NC}"
            else
                echo "$line"
            fi
        done
    else
        echo -e "${RED}Log file not found: $LOG_FILE${NC}"
        echo "Make sure the enhanced WebSocket proxy is running."
    fi
}

# Function to export connection data with converted bytes
export_connection_data() {
    if ! check_database; then
        return 1
    fi
    
    EXPORT_FILE="/tmp/connection_export_$(date +%Y%m%d_%H%M%S).csv"
    echo -e "${BLUE}Exporting connection data to: $EXPORT_FILE${NC}"
    
    # Create header
    echo "real_ip,proxy_ip,connection_type,timestamp,bytes_sent_readable,bytes_received_readable,bytes_sent_raw,bytes_received_raw,duration,status,user_agent" > "$EXPORT_FILE"
    
    # Export data with converted bytes
    sqlite3 "$DB_FILE" "
    SELECT 
        real_ip,
        proxy_ip,
        connection_type,
        timestamp,
        COALESCE(bytes_sent, 0),
        COALESCE(bytes_received, 0),
        duration,
        status,
        user_agent
    FROM connections 
    WHERE timestamp > datetime('now', '-7 days')
    ORDER BY timestamp DESC;
    " | while IFS='|' read -r real_ip proxy_ip conn_type timestamp bytes_sent bytes_rx duration status user_agent; do
        bytes_sent_readable=$(convert_bytes "$bytes_sent")
        bytes_rx_readable=$(convert_bytes "$bytes_rx")
        
        echo "\"$real_ip\",\"$proxy_ip\",\"$conn_type\",\"$timestamp\",\"$bytes_sent_readable\",\"$bytes_rx_readable\",$bytes_sent,$bytes_rx,$duration,\"$status\",\"$user_agent\"" >> "$EXPORT_FILE"
    done
    
    echo -e "${GREEN}Export completed: $(wc -l < $EXPORT_FILE) records exported${NC}"
    echo "File: $EXPORT_FILE"
}

# Function to clean old logs (unchanged)
clean_old_logs() {
    if ! check_database; then
        return 1
    fi
    
    echo -e "${YELLOW}Cleaning logs older than 7 days...${NC}"
    
    # Count records to be deleted
    OLD_COUNT=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM connections WHERE timestamp < datetime('now', '-7 days')")
    
    if [ "$OLD_COUNT" -gt 0 ]; then
        sqlite3 "$DB_FILE" "DELETE FROM connections WHERE timestamp < datetime('now', '-7 days')"
        sqlite3 "$DB_FILE" "VACUUM"
        echo -e "${GREEN}Cleaned $OLD_COUNT old records${NC}"
    else
        echo -e "${BLUE}No old records to clean${NC}"
    fi
}

# Function to show system info (unchanged)
show_system_info() {
    echo -e "${PURPLE}=== Server Information ===${NC}"
    echo -e "${YELLOW}Server IP:${NC} $(get_server_ip)"
    echo -e "${YELLOW}Hostname:${NC} $(hostname)"
    echo -e "${YELLOW}Uptime:${NC} $(uptime | awk '{print $3,$4}' | sed 's/,//')"
    echo -e "${YELLOW}Load Average:${NC} $(uptime | awk -F'load average:' '{print $2}')"
    
    # Check if WebSocket proxy is running
    if pgrep -f "ws-http" > /dev/null; then
        echo -e "${YELLOW}WebSocket Proxy Status:${NC} ${GREEN}Running${NC}"
    else
        echo -e "${YELLOW}WebSocket Proxy Status:${NC} ${RED}Not Running${NC}"
    fi
    
    # Check Caddy status
    if pgrep -f "caddy" > /dev/null; then
        echo -e "${YELLOW}Caddy Reverse Proxy:${NC} ${GREEN}Running${NC}"
    else
        echo -e "${YELLOW}Caddy Reverse Proxy:${NC} ${RED}Not Running${NC}"
    fi
    
    echo ""
}

# Function to show help (unchanged)
show_help() {
    echo -e "${BLUE}Enhanced Connection Monitor - Usage:${NC}"
    echo ""
    echo "Options:"
    echo "  -w, --websocket     Show WebSocket proxy connections with real IPs"
    echo "  -a, --active        Show currently active WebSocket connections"
    echo "  -s, --stats         Show connection statistics"
    echo "  -r, --realtime      Show real-time logs (press Ctrl+C to stop)"
    echo "  -t, --traditional   Show traditional SSH connections"
    echo "  -v, --vpn           Show OpenVPN connections"
    echo "  -i, --info          Show system information"
    echo "  -e, --export        Export connection data to CSV"
    echo "  -c, --clean         Clean old log entries (older than 7 days)"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -w               # Show WebSocket connections with real IPs"
    echo "  $0 -a               # Show active connections"
    echo "  $0 -r               # Monitor real-time logs"
    echo "  $0                  # Show all connection types (default)"
    echo ""
}

# Main function (unchanged)
main() {
    clear
    echo -e "${GREEN}====================================${NC}"
    echo -e "${GREEN}    Enhanced Connection Monitor    ${NC}"
    echo -e "${GREEN}====================================${NC}"
    echo ""
    
    case "${1:-all}" in
        -w|--websocket)
            show_websocket_connections
            ;;
        -a|--active)
            show_active_websocket
            ;;
        -s|--stats)
            show_connection_stats
            ;;
        -r|--realtime)
            show_realtime_logs
            ;;
        -t|--traditional)
            show_ssh_connections
            ;;
        -v|--vpn)
            show_openvpn_connections
            ;;
        -i|--info)
            show_system_info
            ;;
        -e|--export)
            export_connection_data
            ;;
        -c|--clean)
            clean_old_logs
            ;;
        -h|--help)
            show_help
            ;;
        all|*)
            show_system_info
            show_websocket_connections
            show_active_websocket
            show_ssh_connections
            show_openvpn_connections
            ;;
    esac
}

# Cleanup function (unchanged)
cleanup() {
    rm -f /tmp/login-db*.txt /tmp/vpn-login*.txt 2>/dev/null
}

# Set trap for cleanup
trap cleanup EXIT

# Run main function
main "$@"
