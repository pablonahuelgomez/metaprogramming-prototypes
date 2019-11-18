require_relative 'spec_helper'

describe 'Prototyped hierarchy' do
  describe 'a prototyped object' do
    describe 'with many associated prototypes' do
      it 'delegates methods' do
        distancia = prototyped { context.en_kms = 10 }
        corredor = prototyped do
          context.correr = ->(d) { "corriendo #{d.en_kms} kms" }
          context.hacer_ocio = -> { 'jugar al fifa' }
        end

        materia = prototyped { context.nombre = 'marketing' }
        estudiante = prototyped do
          context.estudiar = ->(m) { "estudiando #{m.nombre}" }
          context.hacer_ocio = -> { 'tocar la guitarra' }
        end

        prototype = prototyped.set_prototypes(corredor, Object.new, estudiante)

        expect(prototype.estudiar(materia)).to eq 'estudiando marketing'
        expect(prototype.correr(distancia)).to eq 'corriendo 10 kms'

        expect(prototype.hacer_ocio).to eq 'tocar la guitarra'
      end
    end
  end
end
