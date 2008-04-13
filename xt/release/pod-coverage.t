#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.08; use Pod::Coverage::TrustPod; 1"
  or plan skip_all => "POD coverage testing requires Test::Pod::Coverage 1.08 and Pod::Coverage::TrustPod";

all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::TrustPod' });
