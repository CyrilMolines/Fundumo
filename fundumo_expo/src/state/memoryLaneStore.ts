import AsyncStorage from '@react-native-async-storage/async-storage';
import { differenceInCalendarDays, setYear } from 'date-fns';
import { nanoid } from 'nanoid/non-secure';
import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';

import type { MemoryEntry, ResurfacedMemory } from '../types';

const MAX_ENTRIES = 120;
const SURFACING_WINDOW_DAYS = 21;

type CreateMemoryPayload = {
  title: string;
  description: string;
  capturedOn: Date;
  tags: string[];
  mood?: string;
};

type MemoryLaneState = {
  entries: MemoryEntry[];
  resurfaced: ResurfacedMemory[];
  addMemory: (payload: CreateMemoryPayload) => void;
  deleteMemory: (id: string) => void;
  refreshResurfaced: (referenceDate?: Date) => void;
};

const normalizeDate = (date: Date) => {
  const normalized = new Date(date);
  normalized.setHours(0, 0, 0, 0);
  return normalized;
};

const sanitizeTags = (tags: string[]) =>
  tags
    .map((tag) => tag.trim().toLowerCase())
    .filter((tag) => tag.length > 0)
    .slice(0, 10);

const computeResurfaced = (entries: MemoryEntry[], now: Date): ResurfacedMemory[] => {
  if (!entries.length) {
    return [];
  }
  const todayMidnight = normalizeDate(now);
  return entries
    .map<ResurfacedMemory | null>((entry) => {
      const captured = new Date(entry.capturedOn);
      const comparable = setYear(captured, todayMidnight.getFullYear());
      const offset = Math.abs(differenceInCalendarDays(comparable, todayMidnight));
      if (offset > SURFACING_WINDOW_DAYS) {
        return null;
      }
      return {
        ...entry,
        resurfacedOn: todayMidnight.toISOString(),
        daysOffset: offset,
      };
    })
    .filter((entry): entry is ResurfacedMemory => entry !== null)
    .sort((a, b) => a.daysOffset - b.daysOffset)
    .slice(0, 6);
};

export const useMemoryLaneStore = create<MemoryLaneState>()(
  persist(
    (set, get) => ({
      entries: [],
      resurfaced: [],
      addMemory: ({ title, description, capturedOn, tags, mood }) => {
        const trimmed = title.trim();
        if (!trimmed) {
          throw new Error('Memory title is required.');
        }
        const entry: MemoryEntry = {
          id: nanoid(),
          title: trimmed,
          description: description.trim(),
          capturedOn: normalizeDate(capturedOn).toISOString(),
          tags: sanitizeTags(tags),
          mood: mood?.trim() || undefined,
          createdAt: new Date().toISOString(),
        };
        const current = get().entries;
        const updated = [entry, ...current].slice(0, MAX_ENTRIES);
        set({
          entries: updated,
          resurfaced: computeResurfaced(updated, new Date()),
        });
      },
      deleteMemory: (id: string) => {
        const updated = get().entries.filter((entry) => entry.id !== id);
        set({
          entries: updated,
          resurfaced: computeResurfaced(updated, new Date()),
        });
      },
      refreshResurfaced: (referenceDate?: Date) => {
        const now = referenceDate ?? new Date();
        set({
          resurfaced: computeResurfaced(get().entries, now),
        });
      },
    }),
    {
      name: 'memory-lane',
      storage: createJSONStorage(() => AsyncStorage),
      onRehydrateStorage: () => (state) => {
        if (state) {
          state.resurfaced = computeResurfaced(state.entries, new Date());
        }
      },
    },
  ),
);

