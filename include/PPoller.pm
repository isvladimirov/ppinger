#!/usr/bin/env perl

#######################################
# PPinger
# PPoller.pm
# Class for checking hosts
# Copyright 2018-2019 duk3L3t0
#######################################

package PPoller
{
    use Switch;
    use Net::Ping;
    use strict;

    sub new
    {
        my($class) = @_;
        my $self = {
            NAME => 'PPoller',
            VERSION => '1.0',
        };
        bless $self, $class;
        return $self;
    }

    # Returns '1' if host is alive. Otherwise '0'.
    sub checkHost
    {
        my($self, %host) = @_;
        my($i, $p);
        my $status = undef;
        my $avail; # Availability
        my $dur;   # Duration
        switch ($host{"method"})
        {
            case "ping"
            {
                $p = Net::Ping->new("icmp");
                for ($i = 0; $i<$host{"attempts"}; $i++)
                {
                    ($avail, $dur) = $p->ping($host{"host"}, $host{"timeout"}/1000);
                    if ($avail)
                    {
                        $status = 1;
                        last;
                    }
                }
                $p->close;
                $dur *= 1000; # Convert seconds to milliseconds
            }
            case "tcp"
            {
                $p = Net::Ping->new("tcp");
                $p->port_number($host{"port"});
                for ($i = 0; $i<$host{"attempts"}; $i++)
                {
                    ($avail, $dur) = $p->ping($host{"host"}, $host{"timeout"}/1000);
                    if ($avail)
                    {
                        $status = 1;
                        last;
                    }
                }
                $p->close;
                $dur *= 1000; # Convert seconds to milliseconds
            }
            case "udp"
            {
                $p = Net::Ping->new("udp");
                $p->port_number($host{"port"});
                for ($i = 0; $i<$host{"attempts"}; $i++)
                {
                    ($avail, $dur) = $p->ping($host{"host"}, $host{"timeout"}/1000);
                    print $host{"host"}." ";
                    if ($avail)
                    {
                        $status = 1;
                        last;
                    }
                }
                $p->close;
            }
            case "external"
            {
                if ($host{"command"})
                {
                    ($status, $dur) = split (' ', `$host{"command"} $host{"host"}`);
                }
            }
        }
        return ($status, $dur);
    }
}
1;
