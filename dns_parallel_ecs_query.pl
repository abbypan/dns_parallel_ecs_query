#!/usr/bin/perl
use strict;
use warnings;

use Net::DNS;
use Net::IPAddress::Util qw( IP );
use POSIX;
use Data::Dumper;
use Parallel::ForkManager;

#src_f: recur, subnet xxx.xxx.xxx.xxx/xx, dom, qtype
#dst_f: recur, subnet, dom, qtype, rcode, answer: dom|ttl|class|type|data, ...

my ( $src_f ) = @ARGV;

my $resolver = new Net::DNS::Resolver(

  #nameservers => [ ],
  recurse => 1,

  #debug       => 1
);

$resolver->udp_timeout( 10 );

my $pm = new Parallel::ForkManager( 30 );

open my $fh, '<', $src_f;
while ( my $line = <$fh> ) {
  $pm->start and next;
  chomp( $line );
  my ( $recur, $subnet, $dom, $qtype ) = split /,/, $line;
  $resolver->nameservers( $recur );
  my $packet = new Net::DNS::Packet( $dom, 'IN', $qtype );
  push @{ $packet->{additional} }, gen_ecs_opt( $subnet ) if ( $subnet );
  my $reply    = $resolver->send( $packet );
  my @res_data = ();
  for my $ks ( qw/answer authority/ ) {
    my $kr = $reply->{$ks};
    for my $rr ( @$kr ) {
      my $rs = $rr->string;
      $rs =~ s/\t/|/sg;
      push @res_data, "$ks:$rs";
    }
  }
  my $res_s = join( ";", @res_data );
  my $s = join( ",", $recur, $subnet, $dom, $qtype, $reply->header->rcode, $res_s );
  print $s, "\n";

  $pm->finish;
} ## end while ( my $line = <$fh> )
close $fh;

$pm->wait_all_children;

sub gen_ecs_opt {
  my ( $subnet ) = @_;
  my $ecs_opt = new Net::DNS::RR(
    type  => 'OPT',
    flags => 0,
    rcode => 0,
  );
  my $ecs_val = gen_ecs_val( $subnet );
  $ecs_opt->option( 8 => $ecs_val );
  return $ecs_opt;
}

sub gen_ecs_val {

  #RFC7871
  my ( $subnet ) = @_;
  my ( $ip, $len ) = split '/', $subnet;

  my $addr = IP( $ip );
  my $bits = $ip !~ /:/ ? sprintf( "%032b", $addr->as_n32() ) : join( '', $addr->explode_ip() );

  my $pad_len = 4 * ceil( $len / 4 );
  my $cidr = substr $bits, 0, $pad_len;

  my $family           = sprintf( "%016b", $ip !~ /:/ ? 1 : 2 );
  my $src_prefix_len   = sprintf( "%08b",  $len );
  my $scope_prefix_len = sprintf( "%08b",  0 );

  my $ecs_bits    = join( "", $family, $src_prefix_len, $scope_prefix_len, $cidr );
  my @ecs_bit_arr = $ecs_bits =~ /(....)/g;
  my @ecs_hex     = map { sprintf( "%x", oct( '0b' . $_ ) ) } @ecs_bit_arr;
  my $ecs_val     = pack( 'H*', join( '', @ecs_hex ) );

  return $ecs_val;
} ## end sub gen_ecs_val
