$x = bless {x => 3}, 'Foo';

--- !perl/hash:Foo
x: 3


\ $x;

--- !perl/ref
  =: !perl/hash:Foo
    x: 3

\\ $x;

--- !perl/ref
  =: !perl/ref
    =: !perl/hash:Foo
      x: 3

$moose = 'moose';
$y = bless \$moose, 'Elk';

--- !perl/scalar:Elk moose

\\\$y

--- !perl/ref
  =: !perl/ref
    =: !perl/ref
      =: !perl/scalar:Elk moose

