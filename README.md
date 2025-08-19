# Binario

[SPANISH README](README_sp.md)

Binario is a binary encoding library. It takes any primitive or user define data type and is able to encode into binary or decode it into it's data form. The purpose is to have a language agnostic binary encoding library

`Library is under active development. API and internals may change often for the forseable future`

### Libraries

- [GO](https://github.com/chapgx/binario-go)
- [ODIN](https://github.com/chapgx/binario-odin)
- [RUST](https://github.com/chapgx/binario-rs)

## Quick Use

```odin
package "main"

// path to binario
import "binario"

main :: proc() {
  y: int = 100_000
  z: int
  encoder := binario.encoder_new(size_of(int))
  e := binario.encode(&encoder, y)
  if e != nil {
    panic(e)
  }

  buff := encoder->read()
  decoder := binario.decoder_new(buff)
  e := decoder->decode(z)

  if e != nil {
    panic(e)
  }
  assert(y==z, "y and z must be equal")
}
```


