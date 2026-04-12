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

const device_sessions = table(
  { name: 'device_sessions', public: true },
  {
    browser_fingerprint: t.string().primaryKey(),
    player_id: t.string(),
    session_id: t.string(),
    last_seen_unix_ms: t.f64(),
  }
);

const spacetimedb = schema({ players, device_sessions });
export default spacetimedb;

const DEVICE_SESSION_TIMEOUT_MS = 30_000;

function isSessionActive(lastSeenUnixMs: number, nowUnixMs: number): boolean {
  return nowUnixMs - lastSeenUnixMs <= DEVICE_SESSION_TIMEOUT_MS;
}

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

export const claim_device_session = spacetimedb.reducer(
  {
    player_id: t.string(),
    browser_fingerprint: t.string(),
    session_id: t.string(),
    last_seen_unix_ms: t.f64(),
  },
  (ctx, args) => {
    const existing = ctx.db.device_sessions.browser_fingerprint.find(args.browser_fingerprint);

    if (existing) {
      const occupiedByAnotherSession = existing.session_id !== args.session_id;
      const stillActive = isSessionActive(existing.last_seen_unix_ms, args.last_seen_unix_ms);
      if (occupiedByAnotherSession && stillActive) {
        throw new Error('DEVICE_OCCUPIED: another browser tab is already active for this fingerprint');
      }

      ctx.db.device_sessions.browser_fingerprint.update({
        ...existing,
        player_id: args.player_id,
        session_id: args.session_id,
        last_seen_unix_ms: args.last_seen_unix_ms,
      });
      return;
    }

    ctx.db.device_sessions.insert({
      browser_fingerprint: args.browser_fingerprint,
      player_id: args.player_id,
      session_id: args.session_id,
      last_seen_unix_ms: args.last_seen_unix_ms,
    });
  }
);

export const refresh_device_session = spacetimedb.reducer(
  {
    browser_fingerprint: t.string(),
    session_id: t.string(),
    last_seen_unix_ms: t.f64(),
  },
  (ctx, args) => {
    const existing = ctx.db.device_sessions.browser_fingerprint.find(args.browser_fingerprint);
    if (!existing) {
      throw new Error('DEVICE_SESSION_NOT_FOUND: no active device session found');
    }

    const occupiedByAnotherSession = existing.session_id !== args.session_id;
    const stillActive = isSessionActive(existing.last_seen_unix_ms, args.last_seen_unix_ms);
    if (occupiedByAnotherSession && stillActive) {
      throw new Error('DEVICE_OCCUPIED: another browser tab is already active for this fingerprint');
    }

    ctx.db.device_sessions.browser_fingerprint.update({
      ...existing,
      session_id: args.session_id,
      last_seen_unix_ms: args.last_seen_unix_ms,
    });
  }
);

export const release_device_session = spacetimedb.reducer(
  {
    browser_fingerprint: t.string(),
    session_id: t.string(),
  },
  (ctx, args) => {
    const existing = ctx.db.device_sessions.browser_fingerprint.find(args.browser_fingerprint);
    if (!existing) {
      return;
    }
    if (existing.session_id !== args.session_id) {
      return;
    }
    ctx.db.device_sessions.browser_fingerprint.delete(args.browser_fingerprint);
  }
);
