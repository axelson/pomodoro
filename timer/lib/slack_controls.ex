defmodule Timer.SlackControls do
  @moduledoc """
  Provides an interface to set and clear the user's do not disturb and status
  text.

  Requires the following slack permission scopes:
  * `dnd:write` - For updating the user's do not disturb settings
  * `users.profile:write` - For updating the user's status text
  """

  @token System.fetch_env!("SLACK_TOKEN")

  # DND
  # Slack.Web.Dnd.set_snooze(30, %{token: token})
  # Slack.Web.Dnd.end_snooze(%{token: token})
  def enable_dnd(minutes) do
    Slack.Web.Dnd.set_snooze(minutes, %{token: @token})
  end

  def disable_dnd do
    Slack.Web.Dnd.end_snooze(%{token: @token})
  end

  @doc """
  Set a status for the current user

  Example: SlackControls.set_status("slack'n", ":fire:", duration_minutes: 30)

  That will set the status to "slack'n" with the fire emoji and an expiration
  time of 30 minutes from now
  """
  # Uses: https://api.slack.com/methods/users.profile.set
  # https://api.slack.com/methods/users.profile.set#updating_a_user_s_current_status
  # To set status, both the status_text and status_emoji profile fields must be
  # provided. Optionally, you can also provide a status_expiration field to set
  # a time in the future when the status will clear.
  #
  # * status_text allows up to 100 characters, though we strongly encourage
  #   brevity.
  # * status_emoji is a string referencing an emoji enabled for the Slack team,
  #   such as :mountain_railway:.
  # * status_expiration is an integer specifying seconds since the epoch, more
  #   commonly known as "UNIX time". Providing 0 or omitting this field results
  #   in a custom status that will not expire.
  #
  # Initial instructions found from:
  # https://medium.com/slack-developer-blog/how-to-set-a-slack-status-from-other-apps-ab4eef871339
  #
  # elixir-slack library doesn't support this endpoint directly so it is easiest
  # to just use a direct HTTP Post and avoid the library.
  #
  # Also https://github.com/slackhq/slack-api-docs/ (which doesn't appear well
  # maintained) doesn't have the endpoint either.
  def set_status(status_text, emoji_text \\ "", opts \\ []) do
    duration_minutes = Keyword.get(opts, :duration_minutes)

    status_expiration =
      if duration_minutes do
        current_unix_time() + duration_minutes * 60
      else
        0
      end

    profile =
      Jason.encode!(%{
        status_text: status_text,
        status_emoji: emoji_text,
        status_expiration: status_expiration
      })

    base_uri = "https://slack.com/api/users.profile.set"

    uri = URI.parse(base_uri)
    uri = %URI{uri | query: URI.encode_query(%{profile: profile, token: @token})}

    case HTTPoison.post(uri, "") do
      {:ok, %HTTPoison.Response{status_code: 200} = resp} ->
        case Jason.decode(resp.body) do
          {:ok, %{"ok" => true} = result} -> :ok
          {:ok, %{"error" => error_text}} -> {:error, error_text}
        end

      {:error, _} ->
        {:error, "httpoison error"}
    end
  end

  @doc """
  Clear the current user's status immediately
  """
  # Quoth the docs:
  # > To manually unset a user's custom status, provide empty strings to both
  # > the status_text and status_emoji attributes: "".
  def clear_status do
    set_status("", "")
  end

  defp current_unix_time, do: :os.system_time(:seconds)
end
