defmodule TriviaBuzzer.Repo.Migrations.AddForeignKeys do
  use Ecto.Migration

  def change do
    alter table(:games) do
      modify :winner_id, references(:players, on_delete: :nilify_all)
    end
  end
end
