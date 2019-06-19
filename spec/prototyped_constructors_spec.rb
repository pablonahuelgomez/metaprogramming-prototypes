require_relative 'spec_helper'

describe 'Prototyped Constructors' do
  let(:guerrero) do
    Prototyped::Object.new
                      .set_property(:nombre, 'Guerrero')
                      .set_property(:energia, 100)
                      .set_property(:potencial_defensivo, 10)
                      .set_property(:potencial_ofensivo, 30)
  end

  let(:constructor) do
    Prototyped::Constructor.from(guerrero)
  end
  let(:un_guerrero) do
    constructor.new(
      energia: 200,
      potencial_defensivo: 42,
      potencial_ofensivo: 15
    )
  end

  describe 'singleton methods' do
    describe 'from_prototype' do
      it 'creates a class from a prototype' do
        expect(un_guerrero.energia).to eq(200)
        expect(un_guerrero.potencial_defensivo).to eq(42)
        expect(un_guerrero.potencial_ofensivo).to eq(15)
        expect(un_guerrero.nombre).to eq('Guerrero')
      end

      it 'can assign values' do
        un_guerrero.nombre = "Otro"
        expect(un_guerrero.nombre).to eq('Otro')
      end

      it 'creates properties from keyword arguments' do
        expect(constructor.new(fruta: 42).fruta).to eq(42)
      end
    end
  end

  describe 'instance methods' do
    describe 'extend_with' do
      it 'makes an extension of the constructor with a given block' do
        EspadachinConContexto = constructor.extend_with do |espadachin|
          espadachin.set_property!(:habilidad, 0)
          espadachin.set_property!(:potencial_espada, 0)

          espadachin.set_method!(:potencial_ofensivo) do
            @potencial_ofensivo + context.potencial_espada * context.habilidad
          end
        end

        espadachin = EspadachinConContexto.new(
          energia: 42,
          potencial_ofensivo: 30,
          potencial_defensivo: 10,
          habilidad: 0.5,
          potencial_espada: 30
        )

        expect(espadachin.potencial_ofensivo).to eq(45)
        expect(espadachin.potencial_espada).to eq(30)
      end

      context 'syntax sugar' do

        context 'using #context' do
          it 'makes an extension of the constructor with a given block' do
            EspadachinYContexto = constructor.extend_with do |espadachin|
              espadachin.habilidad = 0
              espadachin.potencial_espada = 0

              espadachin.potencial_ofensivo = ->() do
                @potencial_ofensivo + self.potencial_espada * context.habilidad
              end
            end

            espadachin = EspadachinYContexto.new(
              energia: 42,
              potencial_ofensivo: 30,
              potencial_defensivo: 10,
              habilidad: 0.5,
              potencial_espada: 30
            )

            expect(espadachin.potencial_ofensivo).to eq(45)
            expect(espadachin.potencial_espada).to eq(30)
          end
        end

        context 'using self' do
          it 'makes an extension of the constructor with a given block' do
            EspadachinYSelf = constructor.extend_with do |espadachin|
              espadachin.habilidad = 0
              espadachin.potencial_espada = 0

              espadachin.potencial_ofensivo = ->() do
                @potencial_ofensivo + self.potencial_espada * context.habilidad
              end
            end

            espadachin = EspadachinYSelf.new(
              energia: 42,
              potencial_ofensivo: 30,
              potencial_defensivo: 10,
              habilidad: 0.5,
              potencial_espada: 30
            )

            expect(espadachin.potencial_ofensivo).to eq(45)
            expect(espadachin.potencial_espada).to eq(30)
          end
        end
      end
    end
  end
end
