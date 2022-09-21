### tbh ignore this
[b]Requires Luvit.[b]
I'm putting this repo here just so I don't lose it. I created these scripts for modding some textures for ffxiv to shift the colorset regions from one row to another. If none of that makes sense, don't worry about it.

To further elaborate, I had some complex textures that were already "painted" with some not-so-simple colorset regions, but I needed them shifted to a different colorset row for my modded item.
The script assumes I'm supplying uncompressed TGA textures with BGRA byte order, then remaps the specified alpha channels. In my sample texture, every pixel was already in the colorsets that I wanted to move, and only two pixles were in Row 3, so I just put it in the loop to map those instead to Row 15 instead of 14.

```lua
colsetRowRemap = {}
colsetRowRemap[1] = 15
colsetRowRemap[2] = 16
colsetRowRemap[3] = 14
```

I did this because as far as I can see, TexTools doesn't have it built in to reassign colorset regions on the normal map to new ones. That's it.