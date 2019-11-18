require_relative 'spec_helper'

describe 'Programmatic Prototype' do
  let(:romperlo_todo_a) { ->(o) { o.recibe_danio(o.energia); o } }

  shared_examples :set_a_base_prototype do
    context 'modifying self' do
      it 'can set a base prototype' do
        otro_guerrero = guerrero.clone
        espadachin.set!(guerrero)
        guerrero.set_method!(:sanar) { context.energia += 10 }

        espadachin.sanar

        expect(espadachin.energia).to eq(110)
        expect { otro_guerrero.sanar }.to raise_error(NoMethodError)

        guerrero.set_method!(:potencial_ofensivo) { 1000 }
        expect(espadachin.potencial_ofensivo).to eq(45)
      end
    end

    context 'not modifying self' do
      it 'can set a base prototype' do
        otro_guerrero   = guerrero.clone
        otro_espadachin = espadachin.set(guerrero)
        otro_espadachin.atacar_a(otro_guerrero)
        expect(otro_guerrero.energia).to eq(65.0)
      end
    end
  end

  shared_examples :basic_specs do
    context 'modifying self' do
      it 'can set properties' do
        guerrero.set_property! :nombre, 'Guerrero modificado'
        expect(guerrero.nombre).to eq 'Guerrero modificado'
      end

      it 'can set methods' do
        otro_guerrero = guerrero.clone

        guerrero.set_method!(:romperlo_todo_a, &romperlo_todo_a)
        expect(guerrero).to respond_to(:romperlo_todo_a)

        guerrero_todo_roto = guerrero.romperlo_todo_a(otro_guerrero)
        expect(guerrero_todo_roto.energia).to eq 0
      end
    end

    context 'not modifying self' do
      it 'can set properties' do
        expect(guerrero.nombre).to eq('Guerrero')
        expect(guerrero.energia).to eq(100)
        expect(guerrero.potencial_defensivo).to eq(10)
        expect(guerrero.potencial_ofensivo).to eq(30)

        otro_guerrero = guerrero.set_property(:nombre, 'Otro Guerrero')
        expect(otro_guerrero.nombre).to eq('Otro Guerrero')
        expect(guerrero.nombre).to eq('Guerrero')
      end

      it 'can set methods' do
        otro_guerrero = guerrero.clone
        expect(guerrero).to respond_to(:atacar_a)
        guerrero.atacar_a otro_guerrero
        expect(otro_guerrero.energia).to eq(80)

        poderoso = guerrero.set_method(:romperlo_todo_a, &romperlo_todo_a)
        guerrero_todo_roto = poderoso.romperlo_todo_a(otro_guerrero)

        expect(guerrero).not_to respond_to(:romperlo_todo_a)
        expect(guerrero_todo_roto.energia).to eq 0
      end
    end
  end

  context 'using #context' do
    let(:guerrero) do
      prototyped.set_property(:nombre, 'Guerrero')
                .set_property(:energia, 100)
                .set_property(:potencial_defensivo, 10)
                .set_property(:potencial_ofensivo, 30)
                .set_method(:recibe_danio) { |danio| context.energia -= danio }
                .set_method(:atacar_a) do |otro_guerrero|
        if otro_guerrero.potencial_defensivo < context.potencial_ofensivo
          otro_guerrero.recibe_danio(
            context.potencial_ofensivo - otro_guerrero.potencial_defensivo
          )
        end
      end
    end
    let(:espadachin) do
      prototyped.set_property(:nombre, 'Espadachin')
                .set_property(:habilidad, 0.5)
                .set_property(:potencial_espada, 30)
                .set_property(:potencial_ofensivo, 30)
                .set_method(:potencial_ofensivo) do
        @potencial_ofensivo + (context.potencial_espada * context.habilidad)
      end
    end

    include_examples :basic_specs
    include_examples :set_a_base_prototype
  end

  context 'using self' do
    let(:guerrero) do
      prototyped.set_property(:nombre, 'Guerrero')
                .set_property(:energia, 100)
                .set_property(:potencial_defensivo, 10)
                .set_property(:potencial_ofensivo, 30)
                .set_method(:recibe_danio) { |danio| context.energia -= danio }
                .set_method(:atacar_a) do |otro_guerrero|
        if otro_guerrero.potencial_defensivo < potencial_ofensivo
          otro_guerrero.recibe_danio(
            potencial_ofensivo - otro_guerrero.potencial_defensivo
          )
        end
      end
    end
    let(:espadachin) do
      prototyped.set_property(:nombre, 'Espadachin')
                .set_property(:habilidad, 0.5)
                .set_property(:potencial_espada, 30)
                .set_method(:potencial_ofensivo) do
        @potencial_ofensivo + (potencial_espada * habilidad)
      end
    end

    include_examples :basic_specs
  end
end
