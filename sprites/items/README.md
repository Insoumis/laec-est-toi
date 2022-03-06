
## How to add a new Item

Add their sprites here:

- <item>_<see_below>.png
- text_<item>_<shiver>.png

Load up the editor, it should now detect your new items.


## How we're looking for sprites

We're looking for direction, animation and shiver.

Animation is played on each turn.
Shiver is played 3 times per second or so.

Right now animation is optional but shiver is still mandatory.
> If you're a designer and want to bypass shiver as well, we can probably arrange something.

To get the sprite(s) for an item `example` facing `top left`, we'll try in order:


### The fully qualified path

    <item>_<direction>_<animation>_<shiver>.png
    
    res://sprites/items/example_top_left_0_0.png


### The fully qualified path (without animation)

    <item>_<direction>_<shiver>.png
    
    res://sprites/items/example_top_left_0.png


### An opposite direction

> Nope.
> Vertical symmetry is not done, we only do left-right (below).
> Holler if you think you need it ; it can be done.

    
### Coerced direction to left or right

    <item>_<leftright>_<animation>_<shiver>.png

    res://sprites/items/example_left_0_0.png


### Coerced direction to left or right (without animation)

    <item>_<leftright>_<shiver>.png
    
    res://sprites/items/example_left_0.png


### An opposite left or right direction

    > We'll mirror it for ya
    
    <item>_<leftright>_<animation>_<shiver>.png
    
    res://sprites/items/example_right_0_0.png


### An opposite left or right direction  (without animation)
    
    > We'll mirror it for ya
    
    <item>_<rightleft>_<shiver>.png
    
    res://sprites/items/example_right_0.png


### Ignoring direction

    <item>_<animation>_<shiver>.png

    res://sprites/items/example_0_0.png


### Ignoring direction (without animation)

    <item>_<shiver>.png

    res://sprites/items/example_0.png


### Undefined (trolls)

    undefined_<shiver>.png
