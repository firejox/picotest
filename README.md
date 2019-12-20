# picotest

A tiny test framework for Crystal.

## Features

* No Object class pollution
* No global macro
* Without closure overhead
* Support `assert`, `reject`, `assert_raise`, `reject_raise` basic assertions.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     picotest:
       github: firejox/picotest
   ```

2. Run `shards install`

## Usage

Add this into spec then Run with `crystal spec`

```crystal
require "picotest"
```

### Example Code

```crystal
PicoTest.spec do
  describe "example spec" do
    it "assert true == true" do
       assert true == true
    end

    it "reject true == false" do
      reject true == false
    end

    describe "nest spec" do
      it "catch raise" do
        assert_raise(Exception) do
          raise "OH NO!"
        end
      end

      it "no raise in block" do
        reject_raise do
          "it is safe"
        end
      end
    end

    pending "pending test"

    pending "pending with block" do
    end
  end
end
```

### Before/After Hook

```crystal
# The execution order is A -> D -> F -> E -> B
PicoTest.spec do
  describe "context" do
    before do
      # A
    end

    after do
      # B
    end

    describe "nested context" do
      before do
        # D
      end

      after do
        # E
      end

      it "F" do
      end
    end
  end
end
```

## Development

- [x] `before`, `after` hooks
- [ ] time info records
- [ ] tag on test cases
- [ ] run spec parallel per file in MT mode

## Contributing

1. Fork it (<https://github.com/firejox/picotest/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Firejox](https://github.com/firejox) - creator and maintainer
