require_relative 'spec_helper'

describe 'call_next' do
  context 'the prototyped object has an internal prototype' do
    context 'with params' do
      it 'calls the next implementation' do
        saludador_normal = prototyped
        saludador_normal.saludar = proc { |nombre| "Hola #{nombre}." }
        expect(saludador_normal.saludar('Erlang')).to eq('Hola Erlang.')

        saludador_extra = prototyped.set(saludador_normal)
        saludador_extra.saludar = proc { |nombre| call_next(:saludar, nombre) + ' Como te va?' }
        expect(saludador_extra.saludar('Ruby')).to eq('Hola Ruby. Como te va?')

        saludador_loco = prototyped.set(saludador_extra)
        saludador_loco.saludar = proc { |nombre| call_next(:saludar, nombre) + ' Que agradable sujeto.' }
        expect(saludador_loco.saludar('Matz')).to eq('Hola Matz. Como te va? Que agradable sujeto.')
      end

      it 'delegates any given method to its prototype' do
        libro = prototyped do
          context.titulo = 'El naufrago'
          context.autor  = 'Cesar Aira'
        end

        proto = prototyped
        proto.leer   = ->(l) { "leyendo #{l.titulo}, de #{l.autor}" }
        proto.dormir = ->(horas) { "durmiendo unas #{horas} horas" }

        sub_prototype = prototyped.set(proto)
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
        proto = prototyped
        proto.metodo = proc { 7 }

        sub_prototype = proto.set(proto)
        sub_prototype.metodo = proc { call_next(:metodo) * 2 }
        expect(sub_prototype.metodo).to eq(14)

        test_prototype = proto.set(sub_prototype)
        test_prototype.metodo = proc { call_next(:metodo) + 6 }
        expect(test_prototype.metodo).to eq(20)

        other_prototype = proto.set(test_prototype)
        other_prototype.metodo = proc { call_next(:metodo) + 22 }
        expect(other_prototype.metodo).to eq(42)
      end
    end

    it 'delegates any given method to its prototype' do
      proto = prototyped
      proto.leer   = proc { 'leyendo'   }
      proto.dormir = proc { 'durmiendo' }

      sub_prototype = prototyped.set(proto)
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
      proto = prototyped
      proto.metodo = proc { call_next(:metodo) * 10 }
      expect { proto.metodo }.to(
        raise_error(
          NoMethodError,
          "#The prototype can't handle #metodo"
        )
      )
    end
  end
end
