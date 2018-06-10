# dns_parallel_ecs_query
dns parallel ecs query

# install 

cpanm -n Net::DNS Net::IPAddress::Util Parallel::ForkManager

# usage

    perl dns_parallel_ecs_query.pl src.csv > dst.csv

default parallel processes number: 30

default udp timeout: 10

## src.csv

src_file: recur, subnet xxx.xxx.xxx.xxx/xx, dom, qtype

    8.8.8.8,202.38.64.0/24,www.qq.com,A
    114.114.114.114,202.38.64.0/24,www.qq.com,A
    8.8.8.8,202.38.64.0/24,o-o.myaddr.l.google.com,TXT
    114.114.114.114,202.38.64.0/24,o-o.myaddr.l.google.com,TXT
    114.114.114.114,,o-o.myaddr.l.google.com,TXT
    8.8.8.8,,o-o.myaddr.l.google.com,TXT

## dst.csv

dst_file: recur, subnet, dom, qtype, rcode, answer: dom|ttl|class|type|data, ...

    114.114.114.114,202.38.64.0/24,www.qq.com,A,NOERROR,answer:www.qq.com.|37|IN|A|117.135.169.41
    114.114.114.114,,o-o.myaddr.l.google.com,TXT,NOERROR,answer:o-o.myaddr.l.google.com.|30|IN|TXT|117.135.169.142
    114.114.114.114,202.38.64.0/24,o-o.myaddr.l.google.com,TXT,NOERROR,answer:o-o.myaddr.l.google.com.|30|IN|TXT|117.135.169.142
    8.8.8.8,202.38.64.0/24,o-o.myaddr.l.google.com,TXT,NOERROR,answer:o-o.myaddr.l.google.com.|59|IN|TXT|172.217.46.15;answer:o-o.myaddr.l.google.com.|59|IN|TXT|"edns0-client-subnet 39.190.51.8/32"
    8.8.8.8,,o-o.myaddr.l.google.com,TXT,NOERROR,answer:o-o.myaddr.l.google.com.|59|IN|TXT|172.217.46.3;answer:o-o.myaddr.l.google.com.|59|IN|TXT|"edns0-client-subnet 39.190.51.8/32"
    8.8.8.8,202.38.64.0/24,www.qq.com,A,NOERROR,answer:www.qq.com.|299|IN|A|117.135.169.41
