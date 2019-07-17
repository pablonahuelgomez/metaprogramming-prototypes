module Kernel
  def prototyped(&block)
    Prototyped::Object.new(&block)
  end
end

module Prototyped
  class Object
    def self.new(&block)
      anonymous_class = Class.new
      anonymous_class.new.extend(Prototyped).tap do |o|
        o.instance_exec(&block) unless block.nil?
      end
    end
  end

  class Constructor
    class << self
      def copy(a_prototype)
        Class.new do
          include Prototyped

          define_method(:_prototype) { a_prototype.clone }

          def initialize(args = {})
            copy_prototype!(_prototype)
            args.map { |selector, value| send(:"#{selector}=", value) }
          end
        end
      end # copy

      def from(a_prototype)
        Class.new do
          include Prototyped

          define_method(:_prototype) { a_prototype.clone }

          def initialize(args = {})
            set_prototype!(_prototype)
            args.map { |selector, value| send(:"#{selector}=", value) }
          end

          def self.extend_with(&block)
            Class.new do
              include Prototyped

              define_method(:block) { block }

              def initialize(args = {})
                block.call(self)
                process_input(args)
              end

              private

              def process_input(args)
                args.map do |selector, value|
                  if methods.include?(selector)
                    instance_variable_set(:"@#{selector}", value)
                  else
                    set_property!(selector, value)
                  end
                end
              end
            end # Class.new
          end # self.extend_with
        end # Class.new
      end # from
    end
  end

  attr_reader :prototype

  def set_prototypes(*prototypes)
    clone.tap do |o|
      o.instance_variable_set('@prototype', prototypes.last)
      o.instance_variable_set('@prototypes_hierarchy', prototypes.concat(prototypes.drop(1)))
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

  def set_prototype(a_prototype)
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

  def set_prototype!(a_prototype)
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

  def copy_prototype!(prototype)
    define_singleton_methods_from(prototype)
    set_instance_variables_from(prototype)
  end

  def context
    @context || self
  end

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

  def with_context(a_prototype)
    tap { @context = a_prototype }
  end

  private

  attr_reader :prototypes_hierarchy

  def handle_method_missing(args, block, selector)
    if prototype.nil?
      raise NoMethodError, "#The prototype doesn't know how to handle ##{selector}"
    else
      method_lookup(selector, *args, &block)
    end
  end


  def method_lookup(selector, *args, &block)
    parent = if prototype.respond_to?(selector)
               prototype
             elsif hierarchy_responds_to?(selector)
               implementors(selector).last
             else
               raise NoMethodError, "#The prototype doesn't know how to handle ##{selector}"
             end

    parent.send(selector, *args, &block)
  end

  def hierarchy_responds_to?(selector)
    implementors(selector).any?
  end

  def implementors(selector)
    if prototypes_hierarchy.nil?
      []
    else
      prototypes_hierarchy.select { |prototype| prototype.respond_to?(selector) }
    end
  end

  def handle_call_next(args)
    method_lookup(args.first, *args.drop(1))
  end

  def set_property_in_object(receiver, selector, value)
    receiver.send(:instance_variable_set, :"@#{selector}", value)
    receiver.singleton_class.attr_accessor selector
  end

  def create_method_or_property!(selector, x)
    x.is_a?(Proc) ? set_method!(selector, &x) : set_property!(selector, x)
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
