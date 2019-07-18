require_relative 'spec_helper'

describe 'Syntactic sugar' do
  let(:guerrero_proto) { prototyped }

  before do
    guerrero_proto.energia = 100
    guerrero_proto.potencial_ofensivo = 30
    guerrero_proto.potencial_defensivo = 10
  end

  it 'can set properties' do
    expect(guerrero_proto.energia).to eq(100)
    expect(guerrero_proto.potencial_ofensivo).to eq(30)
    expect(guerrero_proto.potencial_defensivo).to eq(10)
  end

  context 'using self' do
    context 'direct assignment' do
      it 'can set methods' do
        guerrero_proto.atacar_a = ->(otro_guerrero) do
          if otro_guerrero.potencial_defensivo < self.potencial_ofensivo
            otro_guerrero.recibe_danio(
              self.potencial_ofensivo - otro_guerrero.potencial_defensivo
            )
          end
        end
        guerrero_proto.recibe_danio = ->(danio) { self.energia = self.energia - danio }
        guerrero_proto.otro_metodo  = -> { 42 }

        GuerreroConSelf = Prototyped::Constructor.copy(guerrero_proto)
        un_guerrero = GuerreroConSelf.new
        guerrero_proto.atacar_a(un_guerrero)

        expect(un_guerrero.energia).to eq(80)
        expect(guerrero_proto.otro_metodo).to eq(42)
        expect(un_guerrero.otro_metodo).to eq(42)
      end
    end

    context 'indirect assignment through a block' do
      it 'can set methods and properties' do
        perro = prototyped {
          context.nombre    = 'Ed'
          context.edad      = 42
          context.saludar   = ->(nombre) { "hola #{nombre}, mi nombre es #{self.nombre}" }
          context.envejecer = -> { self.edad = self.edad + 1 }
        }

        expect(perro.nombre).to eq('Ed')
        expect(perro.edad).to eq(42)
        expect(perro.saludar('querido amigo')).to eq('hola querido amigo, mi nombre es Ed')

        perro.envejecer
        expect(perro.edad).to eq(43)
      end
    end
  end

  context 'using #context' do
    context 'direct assignment' do
      it 'can set methods' do
        guerrero_proto.atacar_a = ->(otro_guerrero) do
          if otro_guerrero.potencial_defensivo < context.potencial_ofensivo
            otro_guerrero.recibe_danio(
              context.potencial_ofensivo - otro_guerrero.potencial_defensivo
            )
          end
        end
        guerrero_proto.recibe_danio = ->(danio) { context.energia = context.energia - danio }
        guerrero_proto.otro_metodo  = ->() { 42 }

        GuerreroConContexto = Prototyped::Constructor.copy(guerrero_proto)
        un_guerrero = GuerreroConContexto.new
        guerrero_proto.atacar_a(un_guerrero)

        expect(un_guerrero.energia).to eq(80)
        expect(guerrero_proto.otro_metodo).to eq(42)
        expect(un_guerrero.otro_metodo).to eq(42)
      end
    end

    context 'indirect assignment through a block' do
      it 'can set methods and properties' do
        perro = prototyped {
          context.nombre    = 'el lobo gris'
          context.edad      = 42
          context.saludar   = ->(nombre) do
            "hola #{nombre}, mi nombre es #{context.nombre}"
          end
          context.envejecer = -> { context.edad = context.edad + 1 }
        }

        expect(perro.nombre).to eq('el lobo gris')
        expect(perro.edad).to eq(42)
        expect(perro.saludar('querido amigo')).to eq('hola querido amigo, mi nombre es el lobo gris')

        perro.envejecer
        expect(perro.edad).to eq(43)
      end
    end
  end
end
