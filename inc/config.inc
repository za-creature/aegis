//Basic Configuration

{$define debug_l3}

//Automatic Configuration; do not edit unless you really know what you're doing

{$ifdef debug_l3}
 {$define debug_l2}
 {$define debug_l1}
{$endif}

{$ifdef debug_l2}
 {$define debug_l2}
{$endif}