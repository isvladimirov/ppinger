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
        my $status = 0;
        switch ($host{"method"})
        {
            case "ping"
            {
                $p = Net::Ping->new("icmp");
                for ($i = 0; $i<$host{"attempts"}; $i++)
                {
                    if ($p->ping($host{"host"}, $host{"timeout"}/1000))
                    {
                        $status = 1;
                        last;
                    }
                }
                $p->close;
            }
            case "tcp"
            {
                # TODO: Realise tcp check
            }
            case "udp"
            {
                # TODO: Realise udp check
            }
            case "external"
            {
                # TODO: Realise a check with external scripts
            }
        }
        return $status;
    }
}
1;
