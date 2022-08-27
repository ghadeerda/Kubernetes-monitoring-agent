#!/bin/sh 

function now() { 
    #date +%H:%M:%S
    date +%Y-%m-%d\ %H:%M:%S 
    }

/bin/node_exporter $@ &> /dev/null &

NODE_NAME=$(echo $NODE_NAME | sed 's/\-//g')

#db create db
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME \
    -c "create database metrics" &> /dev/null

#db create table
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME \
    -c "CREATE TABLE IF NOT EXISTS  $NODE_NAME \
        (id SERIAL PRIMARY KEY, \
        time timestamp NOT NULL, \
        cpu_sec_idle float NOT NULL, \
        disk_av_per float NOT NULL, \
        disk_read BIGINT NOT NULL, \
        disk_write BIGINT NOT NULL, \
        net_receive BIGINT NOT NULL, \
        mem_pressure BIGINT NOT NULL, 
        mem_av_per float NOT NULL, \
        forks_total BIGINT NOT NULL, \
        intr BIGINT NOT NULL, \
        load1 float NOT NULL, \
        load5 float NOT NULL, \
        load15 float NOT NULL, \
        receive_drop integer NOT NULL, \
        receive_errs integer NOT NULL, \
        transmit_packets integer NOT NULL, \
        tcp_sock_alloc integer NOT NULL, \
        tcp_sock_inuse integer NOT NULL, \
        tcp_sock_mem integer NOT NULL, \
        udp_sock_inuse integer NOT NULL, \
        udp_sock_mem integer NOT NULL, \
        ipv4_sock_inuse integer NOT NULL, \
        est_conn integer NOT NULL, \
        lis_conn integer NOT NULL, \
        open_fds integer NOT NULL, \
        attack integer DEFAULT 0 NOT NULL);" &> /dev/null

k=0
echo "start exporting Node metrics"

while [ $k -lt $RECORDS_NUM ]; do

    curl -s localhost:9100/metrics | grep -v '^#' >/tmp/metrics 
    times=`now`

    #cpu
    cpu_sec_idle="NA"
    cpu_scraper=$(cat /tmp/metrics | grep node_scrape_collector_success | grep -w cpu | awk '{print $2}')
    if [ $cpu_scraper -eq '1' ]; then
        cpu_num=$(cat /tmp/metrics | grep node_cpu_seconds_total | grep idle | wc -l)
        cpu_sum=0
        for i in `seq 1 $cpu_num`
        do
            idle=$(cat /tmp/metrics | grep node_cpu_seconds_total | grep idle | awk '{print $2}'| head -$i | tail -1 | tr -d $'\r')
            cpu_sum=$(echo "scale=4 ; $cpu_sum + $idle " | bc -l)
            cpu_sec_idle=$(echo "scale=4 ; $cpu_sum / $cpu_num" | bc -l)
        done
        # cpuload=$(echo "scale=4 ; (100 - $cpu_sec_idle) * 100" | bc -l)
    fi 

    #disk
    disk_av_per="NA"
    diskstats_scraper=$(cat /tmp/metrics | grep node_scrape_collector_success | grep diskstats | awk '{print $2}')
    if [ $diskstats_scraper -eq '1' ]; then 
        disk_available=$(cat /tmp/metrics | grep 'node_filesystem_avail_bytes' | grep 'host/root\"' |  tr -d $'\r' | awk '{print $2}' | sed 's/e+/*10^/g;s/ /*/' | bc)
        disk_available=${disk_available%.*}
        disk_total=$(cat /tmp/metrics | grep 'node_filesystem_size_bytes' | grep 'host/root\"' |  tr -d $'\r' | awk '{print $2}' | sed 's/e+/*10^/g;s/ /*/' | bc)
        disk_total=${disk_total%.*}
        disk_av_per=$(echo "scale=4 ; ($disk_available * 100)/$disk_total" | bc -l)
    fi 

    #disk
    disk_read="NA"
    disk_write="NA"
    filesystem_scraper=$(cat /tmp/metrics | grep node_scrape_collector_success | grep filesystem | awk '{print $2}')
    if [ $filesystem_scraper -eq '1' ]; then 
        #disk read rate
        disk_read=$(cat /tmp/metrics | grep 'node_disk_read_bytes_total{device="sda"}' | tr -d $'\r'|  awk '{print $2}' | sed 's/e+/*10^/g;s/ /*/' | bc ) 
        disk_read=${disk_read%.*}
        # disk_read=$(echo "scale=4 ; ($disk_read / 1024 )" | bc -l) #convert byte

        #disk written rate
        disk_write=$(cat /tmp/metrics | grep 'node_disk_written_bytes_total{device="sda"}' | tr -d $'\r'|  awk '{print $2}' | sed 's/e+/*10^/g;s/ /*/' | bc ) 
        disk_write=${disk_write%.*}
        # disk_write=$(echo "scale=4 ; ($disk_write / 1024 )" | bc -l) #convert byte
    fi

    #network receive bytes
    net_receive="NA"
    netstat_scraper=$(cat /tmp/metrics | grep node_scrape_collector_success | grep netstat | awk '{print $2}')
    if [ $netstat_scraper -eq '1' ]; then 
        net_receive=$(cat /tmp/metrics | grep 'node_network_receive_bytes_total{device="eth0"}' | tr -d $'\r'|  awk '{print $2}' | sed 's/e+/*10^/g;s/ /*/' | bc ) 
        # net_receive=$(echo "scale=4 ; ($net_receive / 1024 )" | bc -l) #convert byte
    fi

    #memory
    mem_pressure="NA"
    mem_av_per="NA"
    meminfo_scraper=$(cat /tmp/metrics | grep node_scrape_collector_success | grep meminfo | awk '{print $2}')
    if [ $meminfo_scraper -eq '1' ]; then 
        #memory pressure
        mem_pressure=$(cat /tmp/metrics | grep 'node_vmstat_pgmajfault' | awk '{print $2}' |  tr -d $'\r' | sed 's/e+/*10^/g;s/ /*/' | bc )

        #mempory available
        mem_available=$(cat /tmp/metrics | grep 'node_memory_MemAvailable_bytes' | awk '{print $2}' | tr -d $'\r' | sed 's/e+/*10^/g;s/ /*/' | bc )
        mem_available=${mem_available%.*}
        mem_total=$(cat /tmp/metrics | grep 'node_memory_MemTotal_bytes' | awk '{print $2}' | tr -d $'\r' | sed 's/e+/*10^/g;s/ /*/' | bc )
        mem_total=${mem_total%.*}
        mem_av_per=$(echo "scale=4 ; ($mem_available * 100)/$mem_total" | bc -l) #convert byte
    fi 

    #forks total
    forks_total=$(cat /tmp/metrics | grep 'node_forks_total' | awk '{print $2}' |  tr -d $'\r' | sed 's/e+/*10^/g;s/ /*/' | bc )
    forks_total=${forks_total%.*}

    #interrupts
    intr=$(cat /tmp/metrics | grep 'node_intr_total' | awk '{print $2}' |  tr -d $'\r' | sed 's/e+/*10^/g;s/ /*/' | bc )
    intr=${intr%.*}

    #load average
    load1="NA"
    load5="NA"
    load15="NA"
    loadavg_scraper=$(cat /tmp/metrics | grep node_scrape_collector_success | grep loadavg | awk '{print $2}')
    if [ $loadavg_scraper -eq '1' ]; then 
        load1=$(cat /tmp/metrics | grep 'node_load1\ ' | awk '{print $2}' |  tr -d $'\r' | sed 's/e+/*10^/g;s/ /*/' | bc )
        load5=$(cat /tmp/metrics | grep 'node_load5' | awk '{print $2}' |  tr -d $'\r' | sed 's/e+/*10^/g;s/ /*/' | bc )
        load15=$(cat /tmp/metrics | grep 'node_load15' | awk '{print $2}' |  tr -d $'\r' | sed 's/e+/*10^/g;s/ /*/' | bc )
    fi 

    #receive_drop
    receive_drop=$(cat /tmp/metrics | grep 'node_network_receive_drop_total{device="eth0"}' | awk '{print $2}' |  tr -d $'\r' | sed 's/e+/*10^/g;s/ /*/' | bc )
    receive_drop=${receive_drop%.*}

    #receive_errs
    receive_errs=$(cat /tmp/metrics | grep 'node_network_receive_errs_total{device="eth0"}' | awk '{print $2}' |  tr -d $'\r' | sed 's/e+/*10^/g;s/ /*/' | bc )
    receive_errs=${receive_errs%.*}

    #transmit_packets
    transmit_packets=$(cat /tmp/metrics | grep 'node_network_transmit_packets_total{device="eth0"}' | awk '{print $2}' |  tr -d $'\r' | sed 's/e+/*10^/g;s/ /*/' | bc )
    transmit_packets=${transmit_packets%.*}

    #socketstate
    tcp_sock_alloc="NA"
    tcp_sock_inuse="NA"
    tcp_sock_mem="NA"
    udp_sock_inuse="NA"
    udp_sock_mem="NA"
    ipv4_sock_inuse="NA"
    est_conn="NA"
    lis_conn="NA"
    sockstat_scraper=$(cat /tmp/metrics | grep node_scrape_collector_success | grep sockstat | awk '{print $2}')
    if [ $sockstat_scraper -eq '1' ]; then 
        #Number of TCP sockets in state alloc.
        tcp_sock_alloc=$(cat /tmp/metrics | grep -w 'node_sockstat_TCP_alloc' | awk '{print $2}' |  tr -d $'\r' | sed 's/e+/*10^/g;s/ /*/' | bc )

        # Number of TCP sockets in state inuse
        tcp_sock_inuse=$(cat /tmp/metrics | grep -w 'node_sockstat_TCP_inuse' | awk '{print $2}' |  tr -d $'\r' )

        # Number of TCP sockets in state mem
        tcp_sock_mem=$(cat /tmp/metrics | grep -w 'node_sockstat_TCP_mem' | awk '{print $2}' |  tr -d $'\r' | sed 's/e+/*10^/g;s/ /*/' | bc )

        # Number of UDP sockets in state inuse
        udp_sock_inuse=$(cat /tmp/metrics | grep -w 'node_sockstat_UDP_inuse' | awk '{print $2}' |  tr -d $'\r')

        # Number of UDP sockets in state mem
        udp_sock_mem=$(cat /tmp/metrics | grep -w 'node_sockstat_UDP_mem' | awk '{print $2}' |  tr -d $'\r')

        # Number of IPv4 sockets in state inuse
        ipv4_sock_inuse=$(cat /tmp/metrics | grep -w 'node_sockstat_sockets_used' | awk '{print $2}' |  tr -d $'\r' | sed 's/e+/*10^/g;s/ /*/' | bc )

        # Number of established connection states.
        est_conn=$(cat /tmp/metrics | grep -w 'node_tcp_connection_states{state="established"}' | awk '{print $2}' |  tr -d $'\r' | sed 's/e+/*10^/g;s/ /*/' | bc )

        # Number of listen connection states.
        lis_conn=$(cat /tmp/metrics | grep -w 'node_tcp_connection_states{state="listen"}' | awk '{print $2}' |  tr -d $'\r')
    fi

    # Number of open file descriptors.
    open_fds=$(cat /tmp/metrics | grep -w 'process_open_fds' | awk '{print $2}' |  tr -d $'\r')

    #db insert
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME \
        -c "INSERT INTO $NODE_NAME(time, cpu_sec_idle, disk_av_per , disk_read, disk_write, net_receive, mem_pressure, mem_av_per, \
        forks_total, intr, load1, load5, load15, receive_drop, receive_errs, transmit_packets, tcp_sock_alloc, tcp_sock_inuse, \
        tcp_sock_mem, udp_sock_inuse, udp_sock_mem, ipv4_sock_inuse, est_conn, lis_conn, open_fds) \
            VALUES ('$times', $cpu_sec_idle, $disk_av_per , $disk_read, $disk_write, $net_receive, $mem_pressure, $mem_av_per, \
            $forks_total, $intr, $load1, $load5, $load15, $receive_drop, $receive_errs, $transmit_packets, $tcp_sock_alloc, $tcp_sock_inuse, \
            $tcp_sock_mem, $udp_sock_inuse, $udp_sock_mem, $ipv4_sock_inuse, $est_conn, $lis_conn, $open_fds);"

    sleep $INTERVAL
    k=$((k+=1))

done

echo "exporting done"

while true; do 
    sleep 100
done