require_relative 'spec_helper'

describe 'Prototyped hierarchy' do
  describe 'a prototyped object' do
    describe 'with many associated prototypes' do
      it 'delegates methods' do
        distancia = Prototyped::Object.new { context.en_kms = 10 }
        corredor = Prototyped::Object.new do
          context.correr = ->(d) { "corriendo #{d.en_kms} kms" }
          context.hacer_ocio = ->() { 'jugar al fifa' }
        end

        materia = Prototyped::Object.new { context.nombre = 'Obj3' }
        estudiante = Prototyped::Object.new do
          context.estudiar = ->(m) { "estudiando #{m.nombre}" }
          context.hacer_ocio = ->() { 'tocar la guitarra' }
        end

        prototyped = Prototyped::Object.new.set_prototypes(corredor, Object.new, estudiante)

        expect(prototyped.estudiar(materia)).to eq 'estudiando Obj3'
        expect(prototyped.correr(distancia)).to eq 'corriendo 10 kms'

        expect(prototyped.hacer_ocio).to eq 'tocar la guitarra'
      end
    end
  end
end