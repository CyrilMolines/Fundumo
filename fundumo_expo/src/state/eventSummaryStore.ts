import AsyncStorage from '@react-native-async-storage/async-storage';
import { addDays, isSameDay } from 'date-fns';
import { nanoid } from 'nanoid/non-secure';
import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';

import type { EventHighlight, EventSummary } from '../types';

type CreateSummaryPayload = {
  title: string;
  description: string;
  date: Date;
  mediaCount: number;
  highlights: string[];
  tags: string[];
};

type EventSummaryState = {
  summaries: EventSummary[];
  addSummary: (payload: CreateSummaryPayload) => void;
  deleteSummary: (id: string) => void;
  tagCloud: Record<string, number>;
  getSummariesForDate: (date: Date) => EventSummary[];
};

const clampMediaCount = (value: number) => Math.max(0, Math.min(999, value));

const sanitizeHighlights = (values: string[]): EventHighlight[] =>
  values
    .map((text) => text.trim())
    .filter((text) => text.length > 0)
    .slice(0, 8)
    .map((text) => ({ id: nanoid(8), text }));

const sanitizeTags = (tags: string[]) =>
  tags
    .map((tag) => tag.trim().toLowerCase())
    .filter((tag) => tag.length > 0)
    .slice(0, 8);

const buildTagCloud = (summaries: EventSummary[]) => {
  const cloud: Record<string, number> = {};
  summaries.forEach((summary) => {
    summary.tags.forEach((tag) => {
      cloud[tag] = (cloud[tag] ?? 0) + 1;
    });
  });
  return cloud;
};

export const useEventSummaryStore = create<EventSummaryState>()(
  persist(
    (set, get) => ({
      summaries: [],
      tagCloud: {},
      addSummary: ({ title, description, date, mediaCount, highlights, tags }) => {
        const trimmedTitle = title.trim();
        if (!trimmedTitle) {
          throw new Error('Event title cannot be empty.');
        }
        const summary: EventSummary = {
          id: nanoid(),
          title: trimmedTitle,
          description: description.trim(),
          date: date.toISOString(),
          mediaCount: clampMediaCount(mediaCount),
          highlights: sanitizeHighlights(highlights),
          tags: sanitizeTags(tags),
          createdAt: new Date().toISOString(),
        };
        const current = get().summaries;
        const updated = [summary, ...current].slice(0, 50);
        set({
          summaries: updated,
          tagCloud: buildTagCloud(updated),
        });
      },
      deleteSummary: (id: string) => {
        const updated = get().summaries.filter((summary) => summary.id !== id);
        set({
          summaries: updated,
          tagCloud: buildTagCloud(updated),
        });
      },
      getSummariesForDate: (target: Date) =>
        get().summaries.filter((summary) => isSameDay(new Date(summary.date), target)),
    }),
    {
      name: 'event-summaries',
      storage: createJSONStorage(() => AsyncStorage),
      onRehydrateStorage: () => (state) => {
        if (!state) return;
        state.tagCloud = buildTagCloud(state.summaries);
      },
    },
  ),
);

export const getSummariesBetween = (start: Date, end: Date) => {
  const store = useEventSummaryStore.getState();
  return store.summaries.filter((summary) => {
    const date = new Date(summary.date);
    return date >= start && date <= addDays(end, 1);
  });
};

