require_relative 'spec_helper'

describe 'call_next' do
  context 'the prototyped object has an internal prototype' do
    context 'with params' do
      it 'calls the next implementation' do
        saludador_normal = Prototyped::Object.new
        saludador_normal.saludar = proc { |nombre| "Hola #{nombre}. " }

        saludador_extra = Prototyped::Object.new.set_prototype(saludador_normal)
        saludador_extra.saludar = proc { |nombre| call_next(:saludar, nombre) + 'Como te va? ' }
        expect(saludador_extra.saludar('Ruby')).to eq('Hola Ruby. Como te va? ')

        saludador_loco = Prototyped::Object.new.set_prototype(saludador_extra)
        saludador_loco.saludar = proc { |nombre| call_next(:saludar, nombre) + 'Que agradable sujeto. ' }
        expect(saludador_loco.saludar('Matz')).to eq('Hola Matz. Como te va? Que agradable sujeto. ')
      end


      it 'delegates any given method to its prototype' do
        libro = Prototyped::Object.new {
          context.titulo = 'El naufrago'
          context.autor  = 'Cesar Aira'
        }

        prototype = Prototyped::Object.new
        prototype.leer   = ->(l) { "leyendo #{l.titulo}, de #{l.autor}" }
        prototype.dormir = ->(horas) { "durmiendo unas #{horas} horas" }

        sub_prototype = Prototyped::Object.new.set_prototype(prototype)
        sub_prototype.leer   = ->(_) { 'cualquier vegetal' }
        sub_prototype.dormir = ->(_) { 'un reloj digital' }
        sub_prototype.metodo = lambda do
          "#{call_next(:leer, libro)} o #{call_next(:dormir, 7)}"
        end
        expect(sub_prototype.metodo).to eq('leyendo El naufrago, de Cesar Aira o durmiendo unas 7 horas')
      end
    end

    context 'without params' do
      it 'calls the next implementation' do
        prototype = Prototyped::Object.new
        prototype.metodo = proc { 7 }

        sub_prototype = Prototyped::Object.new.set_prototype(prototype)
        sub_prototype.metodo = proc { call_next(:metodo) * 2 }
        expect(sub_prototype.metodo).to eq(14)

        test_prototype = Prototyped::Object.new.set_prototype(sub_prototype)
        test_prototype.metodo = proc { call_next(:metodo) + 6 }
        expect(test_prototype.metodo).to eq(20)

        other_prototype = Prototyped::Object.new.set_prototype(test_prototype)
        other_prototype.metodo = proc { call_next(:metodo) + 22 }
        expect(other_prototype.metodo).to eq(42)
      end
    end

    it 'delegates any given method to its prototype' do
      prototype = Prototyped::Object.new
      prototype.leer   = proc { 'leyendo'   }
      prototype.dormir = proc { 'durmiendo' }

      sub_prototype = Prototyped::Object.new.set_prototype(prototype)
      sub_prototype.leer   = -> { 'cualquier vegetal' }
      sub_prototype.dormir = -> { 'un reloj digital' }
      sub_prototype.metodo = lambda do
        "#{call_next(:leer)} o #{call_next(:dormir)}"
      end
      expect(sub_prototype.metodo).to eq('leyendo o durmiendo')
    end
  end

  context "the prototyped object doesn't have an internal prototype" do
    it 'raises a descriptive error' do
      prototype = Prototyped::Object.new
      prototype.metodo = proc { call_next(:metodo) * 10 }
      expect { prototype.metodo }.to(
        raise_error(
          NoMethodError,
          "#The prototype doesn't know how to handle #metodo"
        )
      )
    end
  end
end