-- Criação das tabelas de Cartões e Investimentos para o Live Bank

-- 1. Tabela de Cartões
CREATE TABLE IF NOT EXISTS public.cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    last_four TEXT NOT NULL,
    holder_name TEXT NOT NULL,
    card_type TEXT NOT NULL CHECK (card_type IN ('virtual', 'physical')),
    is_locked BOOLEAN DEFAULT FALSE,
    cvv TEXT NOT NULL, -- Em um app real, isso seria criptografado
    expiry_date TEXT NOT NULL, -- Formato MM/YY
    label TEXT, -- Nome personalizado para o cartão (ex: "Compras Online")
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Tabela de Investimentos
CREATE TABLE IF NOT EXISTS public.investments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    asset_type TEXT NOT NULL, -- 'CDB', 'Tesouro Direto', 'Ações', etc.
    asset_name TEXT NOT NULL,
    amount DECIMAL(15, 2) NOT NULL DEFAULT 0,
    purchase_price DECIMAL(15, 2) NOT NULL,
    purchase_date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    current_yield DECIMAL(5, 2) DEFAULT 0, -- Rentabilidade acumulada
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Habilitar RLS
ALTER TABLE public.cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.investments ENABLE ROW LEVEL SECURITY;

-- Políticas de Segurança (RLS)

-- Cartões: Apenas o dono pode ver e gerenciar seus cartões
CREATE POLICY "Users can view their own cards" ON public.cards
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own cards" ON public.cards
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own cards" ON public.cards
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own cards" ON public.cards
    FOR DELETE USING (auth.uid() = user_id);

-- Investimentos: Apenas o dono pode ver e gerenciar seus investimentos
CREATE POLICY "Users can view their own investments" ON public.investments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own investments" ON public.investments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Trigger para updated_at em cards
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_cards_updated_at BEFORE UPDATE ON public.cards
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
