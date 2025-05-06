# Binario

[SPANISH README](README_sp.md)

Binario is a binary encoding library. It takes any primitive or user define data type and is able to encode into binary or decode it into it's data form. The purpose is to have a language agnostic binary encoding library

`Library is under active development. API and internals may change often for the forseable future`

### Languges

- [GO](https://go.dev)
- [ODIN](https://odin-lang.go)
- [RUST](https://rust-lang.org)

## Quick Use

```odin
package "main"

// path to binario
import "binario"

main :: proc() {
  y: int = 100_000
  z: int
  buff, e := binario.encode(y)
  if e != nil {
    panic(e)
  }
  e = binario.decode(buff, z)
  if e != nil {
    panic(e)
  }
  assert(y==z, "y and z must be equal")
}
```


