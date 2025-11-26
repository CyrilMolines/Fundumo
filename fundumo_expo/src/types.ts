export type EventHighlight = {
  id: string;
  text: string;
};

export type EventSummary = {
  id: string;
  title: string;
  description: string;
  date: string;
  mediaCount: number;
  highlights: EventHighlight[];
  tags: string[];
  createdAt: string;
};

export type MemoryEntry = {
  id: string;
  title: string;
  description: string;
  capturedOn: string;
  tags: string[];
  mood?: string;
  createdAt: string;
};

export type ResurfacedMemory = MemoryEntry & {
  resurfacedOn: string;
  daysOffset: number;
};

export type FeedbackEntry = {
  id: string;
  topic: string;
  message: string;
  mood?: string;
  createdAt: string;
  anonymousCode: string;
  sharedAt?: string;
  resolvedAt?: string;
};

