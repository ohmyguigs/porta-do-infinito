import { schema, table, t } from 'spacetimedb/server';

const players = table(
  { name: 'players', public: true },
  {
    player_id: t.string().primaryKey(),
    browser_fingerprint: t.string().index('btree'),
    display_name: t.string(),
    guild: t.string(),
    role: t.string(),
    player_state: t.string(),
    pos_x: t.f64(),
    pos_y: t.f64(),
    last_seen_unix_ms: t.f64(),
  }
);

const spacetimedb = schema({ players });
export default spacetimedb;

export const upsert_player = spacetimedb.reducer(
  {
    player_id: t.string(),
    browser_fingerprint: t.string(),
    display_name: t.string(),
    guild: t.string(),
    role: t.string(),
    player_state: t.string(),
    pos_x: t.f64(),
    pos_y: t.f64(),
    last_seen_unix_ms: t.f64(),
  },
  (ctx, args) => {
    const existing = ctx.db.players.player_id.find(args.player_id);

    if (existing) {
      ctx.db.players.player_id.update({
        ...existing,
        browser_fingerprint: args.browser_fingerprint,
        display_name: args.display_name,
        guild: args.guild,
        role: args.role,
        player_state: args.player_state,
        pos_x: args.pos_x,
        pos_y: args.pos_y,
        last_seen_unix_ms: args.last_seen_unix_ms,
      });
      return;
    }

    ctx.db.players.insert({
      player_id: args.player_id,
      browser_fingerprint: args.browser_fingerprint,
      display_name: args.display_name,
      guild: args.guild,
      role: args.role,
      player_state: args.player_state,
      pos_x: args.pos_x,
      pos_y: args.pos_y,
      last_seen_unix_ms: args.last_seen_unix_ms,
    });
  }
);

export const heartbeat_player = spacetimedb.reducer(
  {
    player_id: t.string(),
    last_seen_unix_ms: t.f64(),
  },
  (ctx, args) => {
    const existing = ctx.db.players.player_id.find(args.player_id);
    if (!existing) {
      return;
    }

    ctx.db.players.player_id.update({
      ...existing,
      last_seen_unix_ms: args.last_seen_unix_ms,
    });
  }
);
