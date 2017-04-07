# Verifly v0.1
[![Build Status](https://travis-ci.org/umbrellio/verifly.svg?branch=master)]
(https://travis-ci.org/umbrellio/verifly)

This gem consists of several dependent components, which all could be
used standalone. The most important one is [Verifier](#Verifier),
but understanding [Applicator](#Applicator) and
[ApplicatorWithOptions](#ApplicatorWithOptions) helps understand its API.
The least important one, [ClassBuilder](#ClassBuilder), is only used in private APIs,
but its own API is public

## Instalation

```
$ gem install verifly
```

and then in code

```
require 'verifly'
```

## ClassBuilder

example:

```lang=ruby
Abstract = Struct.new(:data)
  extend Verifly::ClassBuilder::Mixin

  class WithString < self
    def self.build_class(x)
      self if x.is_a?(String)
    end
  end

  Generic = Class.new(self)

  self.buildable_classes = [WithString, Generic]
  # or, vice versa
  def self.buildable_classes
    [WithString, Generic]
  end
end

Abstract.build("foo") # => WithString.new("foo")
Abstract.build(:foo) # => Generic.new("foo")
```

or see lib/verifier/applicator.rb

Why don't just use Uber::Builder?
([Uber](https://github.com/apotonick/uber) is cool, you should try it)
There are two reasons: firstly, it is an unnecessary dependency.
We dont want npm hell, do we? Uber::Builder realy does not do much work,
it's just a pattern. Secondly, this implementation looks more clear to me,
because children are deciding whether they will handle arguments, not parents.

So to use it, you have to:

1. Write some classes with duck type `.class_builder(*args)`

2. Invoke `Verifly::ClassBuilder.new([<%= array_of_classes %>]).call(*args)`

3. ????

4. PROFIT

It's simple and clear, but not very sugary. So, otherwise, you may do
following:

1. Write an abstract class

2. Extend `Verifly::ClassBuilder::Mixin`

3. Inherit from the abstract class in different implementations

4. If some implementations have common ancestors
(not including the abstract class), you can implement common ancestor's
`.build_class` in terms of super (i.e.
`def self.build_class(x); super if x.is_a?(String); end`)

5. Change `.build_class` of other classes like `self if ...`.
Don't change default implementation's `.build_class`

6. Setup `.buildable_classes` on the abstract class, mentioning only direct chldren
if you done step 4

7. Optionally redefine `.build` in abstract class, if you want
to separate `build_class` and constructor params

8. Use `.build` instead of `new`

## Applicator

Applicator is designed to wrap applications of
[applicable](https://en.wikipedia.org/wiki/Sepulka) objects
around some binding in some context

example:

```lang=ruby
object = OpenStruct.new(foo: :bar)
Applicator.call(:foo, object, {}) # => :bar
Applicator.call('foo', object, {}) # => :bar
Applicator.call('context', object, {}) # => {}
Applicator.call(-> { foo }, object, {}) # => :bar
Applicator.call(->(context) { context[foo] }, object, bar: :baz) # => :baz
Applicator.call(true, object, {}) # => true

foo = :bar
Applicator.call(:foo, binding, {}) # => :bar
Applicator.call('object.foo', binding, {}) # => :bar
```

Applicator is good, but in most cases
[ApplicatorWithOptions](#ApplicatorWithOptions) would be a better option.

## ApplicatorWithOptions

ApplicatorWithOptions is an applicator with options.
The options are `if: ` and `unless: `. Same as in ActiveModel::Validations,
they are applied to the same binding. Main action is executed
only if `if: ` evaluates to truthy and `unless: ` evaluates to falsey.

See examples:

```lang=ruby
ApplicatorWithOptions.new(:foo, if: -> { true }).call(binding, {}) # => foo

ApplicatorWithOptions.new(:foo, if: -> (context) { context[:bar] })
  .call(binding, { bar: true }) # => foo

ApplicatorWithOptions.new(:foo, if: { bar: true }).call(binding, :bar) # => foo

ApplicatorWithOptions.new(:foo, unless: -> { true })
  .call(binding, {}) # => nil
ApplicatorWithOptions.new(:foo, unless: -> (context) { context[:bar] })
  .call(binding, { bar: true }) # => foo
ApplicatorWithOptions.new(:foo, unless: { bar: true })
  .call(binding, :bar) # => nil
```

## Verifier

The last, but the most interesting component is Verifier.
Verifiers use ApplciatorWithOptions to execute generic procedures.
Procedures should call `message!` if they want to yield something.
Note that you should implement `message!` by yourself (in terms of super)

```lang=ruby
class MyVerifier < Verifly::Verifier
  Message = Struct.new(:text)
  verify :foo, if: { foo: true }

  private

  def message!(text)
    super { Message.new(text) }
  end

  def foo
    message!('Something is wrong') if Fixnum != Bignum
  end
end
```

In addition to Applicator's power, you also can nest your verifiers
to split the logic

```lang=ruby
class MyVerifier < Verifly::Verifier
  Message = Struct.new(:text)
  verify ChildVerifier, if: -> (context) { cotnext[:foo] }

  private

  def message!(text)
    super { Message.new(text) }
  end
end

class ChildVerifier < MyVerifier
  verify %q(message!("it's alive!"))
end
```
