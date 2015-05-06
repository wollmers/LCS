package LCS;

use strict;
use warnings;

use 5.008;
our $VERSION = '0.01';

use Data::Dumper;

sub new {
  my $class = shift;
  # uncoverable condition false
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}


sub lcs2align {
  my ($self, $X, $Y, $LCS) = @_;

  my $hunks = [];

  my $Xcurrent = -1;
  my $Ycurrent = -1;
  my $Xtemp;
  my $Ytemp;

  for my $hunk (@$LCS) {
    while ( ($Xcurrent+1 < $hunk->[0] ||  $Ycurrent+1 < $hunk->[1]) ) {
      $Xtemp = '';
      $Ytemp = '';
      if ($Xcurrent+1 < $hunk->[0]) {
        $Xcurrent++;
        $Xtemp = $X->[$Xcurrent];
      }
      if ($Ycurrent+1 < $hunk->[1]) {
        $Ycurrent++;
        $Ytemp = $Y->[$Ycurrent];
      }
      push @$hunks,[$Xtemp,$Ytemp];
    }

    $Xcurrent = $hunk->[0];
    $Ycurrent = $hunk->[1];
    push @$hunks,[$X->[$Xcurrent],$Y->[$Ycurrent]]; # elements
  }
  while ( ($Xcurrent+1 <= $#$X ||  $Ycurrent+1 <= $#$Y) ) {
    $Xtemp = '';
    $Ytemp = '';
    if ($Xcurrent+1 <= $#$X) {
      $Xcurrent++;
      $Xtemp = $X->[$Xcurrent];
    }
    if ($Ycurrent+1 <= $#$Y) {
      $Ycurrent++;
      $Ytemp = $Y->[$Ycurrent];
    }
    push @$hunks,[$Xtemp,$Ytemp];
  }
  return $hunks;
}

sub sequences2hunks {
  my ($self, $a, $b) = @_;
  return [ map { [ $a->[$_], $b->[$_] ] } 0..$#$a ];
}

sub hunks2sequences {
  my ($self, $hunks) = @_;

  my $a = [];
  my $b = [];

  for my $hunk (@$hunks) {
    push @$a, $hunk->[0];
    push @$b, $hunk->[1];
  }
  return ($a,$b);
}

sub align2strings {
  my ($self, $hunks,$gap) = @_;
  $gap //= '_';

  my $a = '';
  my $b = '';

  for my $hunk (@$hunks) {
    my ($ae,$be) = $self->fill_strings($hunk->[0],$hunk->[1],$gap);
    $a .=  $ae;
    $b .=  $be;
  }
  return ($a,$b);
}

sub fill_strings {
  my ($self, $string1,$string2, $gap) = @_;
  $gap //= '_';

  my @m = $string1 =~ m/(\X)/g;
  my @n = $string2 =~ m/(\X)/g;
  my $max = max(scalar(@m),scalar(@n));
  if ($max - scalar(@m) > 0) {
    for (1..$max-scalar(@m)) {
      $string1 .= $gap;
    }
  }
  if ($max - scalar(@n) > 0) {
    for (1..$max-scalar(@n)) {
      $string2 .= $gap;
    }
  }
  return ($string1,$string2);
}

sub LLCS {
  my ($self,$X,$Y) = @_;

  my $m = scalar @$X;
  my $n = scalar @$Y;

  my $c = [];

  for my $i (0..1) {
    for my $j (0..$n) {
      $c->[$i][$j]=0;
    }
  }

  my ($i,$j);

  for ($i=1; $i <= $m; $i++) {
    for ($j=1; $j <= $n; $j++) {
      if ($X->[$i-1] eq $Y->[$j-1]) {
        $c->[1][$j] = $c->[0][$j-1]+1;
      }
      else {
        $c->[1][$j] = max($c->[1][$j-1],$c->[0][$j]);
      }
    }
    for ($j = 1; $j <= $n; $j++) {
      $c->[0][$j] = $c->[1][$j];
    }
  }
  return ($c->[1][$n]);
}


sub LCS {
  my ($self,$X,$Y) = @_;

  my $m = scalar @$X;
  my $n = scalar @$Y;

  my $c = [];
  my ($i,$j);
  for ($i=0;$i<=$m;$i++) {
    for ($j=0;$j<=$n;$j++) {
      $c->[$i][$j]=0;
    }
  }
  for ($i=1;$i<=$m;$i++) {
    for ($j=1;$j<=$n;$j++) {
      if ($X->[$i-1] eq $Y->[$j-1]) {
        $c->[$i][$j] = $c->[$i-1][$j-1]+1;
      }
      else {
        $c->[$i][$j] = max($c->[$i][$j-1], $c->[$i-1][$j]);
      }
    }
  }
  my $path = $self->_print_lcs($X,$Y,$c,$m,$n,[]);
  return $path;
}


sub max {
  ($_[0] > $_[1]) ? $_[0] : $_[1];
}

sub _print_lcs {
  my ($self,$X,$Y,$c,$i,$j,$L) = @_;

  if ($i==0 || $j==0) { return ([]); }
  if ($X->[$i-1] eq $Y->[$j-1]) {
    $L = $self->_print_lcs($X,$Y,$c,$i-1,$j-1,$L);
    #print $X->[$i-1];
    push @{$L},[$i-1,$j-1];
  }
  elsif ($c->[$i][$j] == $c->[$i-1][$j]) {
    $L = $self->_print_lcs($X,$Y,$c,$i-1,$j,$L);
  }
  else {
    $L = $self->_print_lcs($X,$Y,$c,$i,$j-1,$L);
  }
  return $L;
}


sub _all_lcs {
  my ($self,$ranks,$rank,$max) = @_;

  my $R;
  if ($rank > $max) {return [[]]} # no matches
  if ($rank == $max) {
    return [ map { [$_] } @{$ranks->{$rank}} ];
  }

  my $tails = $self->_all_lcs($ranks,$rank+1,$max);
  for my $tail (@$tails) {
    for my $hunk (@{$ranks->{$rank}}) {
      if (($tail->[0][0] > $hunk->[0]) && ($tail->[0][1] > $hunk->[1])) {
        push @$R,[$hunk,@$tail];
      }
    }
  }
  return $R;
}

# get all LCS of two arrays
# records the matches by rank
sub allLCS {
  my ($self,$X,$Y) = @_;

  my $m = scalar @$X;
  my $n = scalar @$Y;

  my $ranks = {}; # e.g. '4' => [[3,6],[4,5]]
  my $c = [];
  my ($i,$j);

  for (0..$m) {$c->[$_][0]=0;}
  for (0..$n) {$c->[0][$_]=0;}
  for ($i=1;$i<=$m;$i++) {
    for ($j=1;$j<=$n;$j++) {
      if ($X->[$i-1] eq $Y->[$j-1]) {
        $c->[$i][$j] = $c->[$i-1][$j-1]+1;
        push @{$ranks->{$c->[$i][$j]}},[$i-1,$j-1];
      }
      else {
        $c->[$i][$j] =
          ($c->[$i][$j-1] > $c->[$i-1][$j])
            ? $c->[$i][$j-1]
            : $c->[$i-1][$j];
      }
    }
  }
  my $max = scalar keys %$ranks;
  return $self->_all_lcs($ranks,1,$max);
}



1;
__END__

=encoding utf-8

=head1 NAME

LCS - Longest Common Subsequence

=head1 SYNOPSIS

  use LCS;

=head1 DESCRIPTION

LCS is an implementation based on a LCS algorithm.

=head2 CONSTRUCTOR

=over 4

=item new()

Creates a new object which maintains internal storage areas
for the LCS computation.  Use one of these per concurrent
LCS() call.

=back

=head2 METHODS

=over 4


=item LCS(\@a,\@b)

Finds a Longest Common Subsequence, taking two arrayrefs as method
arguments. It returns an array reference of corresponding
indices, which are represented by 2-element array refs.

=item LLCS(\@a,\@b)

Calculates the length of the Longest Common Subsequence.

=item allLCS(\@a,\@b)

Finds all Longest Common Subsequences. It returns an array reference of all
LCS.

=item lcs2align(\@a,\@b,$LCS)

Returns the two sequences aligned, missing positions are represented as empty strings.

=item sequences2hunks($a, $b)

Transforms two array references of scalars to an array of hunks (two element arrays).

=item hunks2sequences($hunks)

Transforms an array of hunks to two arrays of scalars.

=item align2strings($hunks, $gap_character)

Returns two strings aligned with gap characters.

=item fill_strings($string1, $string2, $fill_character)

If one of the two strings is shorter, fills it up to the same length.

=item max($i, $j)

Returns the maximum of two numbers.

=back

=head2 EXPORT

None by design.


=head1 AUTHOR

Helmut Wollmersdorfer E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Helmut Wollmersdorfer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
