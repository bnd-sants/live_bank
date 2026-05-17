-- Tabela de usuários
create table if not exists users (
  user_id uuid references auth.users(id) primary key,
  nome text not null,
  email text unique not null,
  cpf text unique not null,
  telefone text,
  tipo_pessoa text default 'fisica',
  foto text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Tabela de contas para saldo
create table if not exists accounts (
  user_id uuid references auth.users(id) primary key,
  balance float8 not null default 30000.0
);

-- Tabela de transferências (histórico)
create table if not exists transfers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  destinatario text not null,
  valor float8 not null,
  moeda text,
  valor_original float8,
  data timestamp with time zone default now()
);

-- Função para atualizar o timestamp de updated_at
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Trigger para atualizar o updated_at automaticamente
create trigger update_users_updated_at
  before update on users
  for each row
  execute function update_updated_at_column();

-- Função para criar perfil automaticamente no cadastro
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.users (user_id, nome, email, cpf, telefone, tipo_pessoa)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nome', 'Usuário'),
    new.email,
    coalesce(new.raw_user_meta_data->>'cpf', '000.000.000-00'),
    new.raw_user_meta_data->>'telefone',
    coalesce(new.raw_user_meta_data->>'tipo_pessoa', 'fisica')
  );

  insert into public.accounts (user_id, balance)
  values (new.id, 30000.0);

  return new;
end;
$$;

-- Trigger para chamar a função após o insert no auth.users
create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
