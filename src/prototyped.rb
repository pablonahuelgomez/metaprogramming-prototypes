module Kernel
  def prototyped(&block)
    Prototyped::Object.new(&block)
  end
end

module Prototyped
  class Object
    def self.new(&block)
      anonymous = Class.new.new
      anonymous.extend(Prototyped).tap do |object|
        object.instance_exec(&block) unless block.nil?
      end
    end
  end

  class CopyLogic
    def self.exec(p)
      Class.new do
        include Prototyped

        define_method(:_prototype) { p.clone }

        def initialize(args = {})
          copy!(_prototype)
          args.map { |selector, value| send(:"#{selector}=", value) }
        end
      end
    end
  end

  class ExtendWithLogic
    def self.exec(&block)
      Class.new do
        include Prototyped
        define_method(:block) { block }

        def initialize(args = {})
          block.call(self)
          process_input(args)
        end

        private

        def process_input(args)
          args.map(&method(:choose))
        end

        def choose(selector, value)
          if methods.include?(selector)
            instance_variable_set(:"@#{selector}", value)
          else
            set_property!(selector, value)
          end
        end
      end
    end
  end

  class FromLogic
    def self.exec(p)
      Class.new do
        include Prototyped
        define_method(:_prototype) { p.clone }

        def initialize(args = {})
          set!(_prototype)
          args.map { |selector, value| send(:"#{selector}=", value) }
        end

        def self.extend_with(&block)
          ExtendWithLogic.exec(&block)
        end
      end
    end
  end

  class Constructor
    class << self
      def copy(prototype)
        CopyLogic.exec(prototype)
      end

      def from(prototype)
        FromLogic.exec(prototype)
      end
    end
  end

  attr_reader :prototype

  def set_prototypes(*prototypes)
    clone.tap do |o|
      o.instance_variable_set('@prototype', prototypes.last)
      o.instance_variable_set('@hierarchy', prototypes.concat(prototypes.drop(1)))
    end
  end

  # Sets a property for the current instance, *modifying* self.
  #
  # @param selector [Symbol] the property name, `:any_symbol`
  # @param value [Symbol] the property value, `:text` or `:html`
  # @return [Prototyped] the prototyped object with the new property.
  def set_property!(selector, value)
    tap { set_property_in_object(self, selector, value) }
  end

  # Sets a property for a clone of self.
  #
  # @param selector [Symbol] the property name, `:any_symbol`
  # @param value [Symbol] the property value, `:text` or `:html`
  # @return [Prototyped] the cloned prototyped object with the new property.
  def set_property(selector, value)
    clone.tap { |o| set_property_in_object(o, selector, value) }
  end

  # Defines a method in a clone of self.
  #
  # @param selector [Symbol] the method name, `:any_symbol`
  # @param block [Symbol] the body of the method
  # @return [Prototyped] the cloned prototyped object which responds to :selector.
  def set_method(selector, &block)
    clone.tap { |o| o.define_singleton_method(selector, &block) }
  end

  # Defines a method in the current instance, *modifying* self.
  #
  # @param selector [Symbol] the method name, `:any_symbol`
  # @param block [Proc] the body of the method
  # @return [Prototyped] the prototyped object which responds to :selector.
  def set_method!(selector, &block)
    tap { define_singleton_method(selector, &block) }
  end

  def set(a_prototype)
    clone.tap do |o|
      a_prototype.instance_variables.map do |inst_var_selector|
        o.instance_variable_set(
          inst_var_selector,
          a_prototype.instance_variable_get(inst_var_selector)
        )
      end
      o.instance_variable_set(:"@prototype", a_prototype.with_context(o))
    end
  end

  def set!(a_prototype)
    tap do
      prototype.instance_variables.map do |inst_var_selector|
        instance_variable_set(
          inst_var_selector,
          a_prototype.instance_variable_get(inst_var_selector)
        )
      end
      @prototype = a_prototype.with_context(self)
    end
  end

  def copy!(prototype)
    define_singleton_methods_from(prototype)
    set_instance_variables_from(prototype)
  end

  def context
    @context || self
  end

  def with_context(a_prototype)
    tap { @context = a_prototype }
  end

  private

  attr_reader :hierarchy

  def method_missing(selector, *args, &block)
    received_method = selector.to_s

    if received_method.match(/=/)
      clean_selector = received_method.delete('=')
      x = args.first

      create_method_or_property!(clean_selector, x)
    elsif received_method == 'call_next'
      handle_call_next(args)
    else
      handle_method_missing(args, block, selector)
    end
  end

  def handle_method_missing(args, block, selector)
    if prototype.nil?
      raise NoMethodError, "#The prototype doesn't know how to handle ##{selector}"
    else
      method_lookup(selector, *args, &block)
    end
  end

  def method_lookup(selector, *args, &block)
    identify_parent(selector).send(selector, *args, &block)
  end

  def identify_parent(selector)
    if prototype.respond_to?(selector)
      prototype
    elsif hierarchy_responds_to?(selector)
      implementors(selector).last
    else
      raise NoMethodError, "#The prototype can't handle ##{selector}"
    end
  end

  def hierarchy_responds_to?(selector)
    implementors(selector).any?
  end

  def implementors(selector)
    if hierarchy.nil?
      []
    else
      hierarchy.select { |prototype| prototype.respond_to?(selector) }
    end
  end

  def handle_call_next(args)
    method_lookup(args.first, *args.drop(1))
  end

  def set_property_in_object(receiver, selector, value)
    receiver.send(:instance_variable_set, :"@#{selector}", value)
    receiver.singleton_class.attr_accessor selector
  end

  def create_method_or_property!(selector, proc_or_value)
    if proc_or_value.is_a?(Proc)
      set_method!(selector, &proc_or_value)
    else
      set_property!(selector, proc_or_value)
    end
  end

  def set_instance_variables_from(prototype)
    prototype.instance_variables.map do |inst_var_selector|
      instance_variable_set(
        inst_var_selector,
        prototype.instance_variable_get(inst_var_selector)
      )
    end
  end

  def define_singleton_methods_from(prototype)
    (prototype.methods - context.methods).map do |selector|
      define_singleton_method(
        selector,
        &prototype.singleton_method(selector)
      )
    end
  end
end
